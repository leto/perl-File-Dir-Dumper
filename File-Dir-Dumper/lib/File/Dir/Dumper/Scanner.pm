package File::Dir::Dumper::Scanner;

use warnings;
use strict;

use base 'File::Dir::Dumper::Base';

use Carp;

use File::Find::Object;

use POSIX qw(strftime);
use List::Util qw(min);

__PACKAGE__->mk_accessors(
    qw(
    _file_find
    _queue
    _last_result
    )
);

=head1 NAME

File::Dir::Dumper::Scanner - scans a directory and returns a stream of Perl
hash-refs

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use File::Dir::Dumper::Scanner;

    my $writer = File::Dir::Dumper::Scanner->new(
        {
            dir => $dir_pathname
        }
    );

    while (defined(my $token = File::Dir::Dumper::Scanner->fetch()))
    {
    }

=head1 METHODS

=head2 $self->new({ dir => $dir_path})

Scans the directory $dir_path.

=head2 my $hash_ref = $self->fetch()

Outputs the next token as a hash ref.

=cut

sub _init
{
    my $self = shift;
    my $args = shift;

    my $dir_to_dump = $args->{dir};

    $self->_file_find(
        File::Find::Object->new(
            {
                followlink => 0,
            },
            $dir_to_dump,
        )
    );

    $self->_queue([]);

    $self->_add({ type => "header", dir_to_dump => $dir_to_dump});
    
    return;
}

sub _add
{
    my $self = shift;
    my $token = shift;

    push @{$self->_queue()}, $token;

    return;
}

sub fetch
{
    my $self = shift;

    if (! @{$self->_queue()})
    {
        $self->_populate_queue();
    }

    return shift(@{$self->_queue()});
}

sub _up_to_level
{
    my $self = shift;
    my $target_level = shift;

    my $last_result = $self->_last_result();

    for my $level (
        reverse($target_level .. $#{$last_result->dir_components()})
    )
    {
        $self->_add(
            {
                type => "updir",
                depth => $level+1,
            }
        )
    }

    return;
}

sub _populate_queue
{
    my $self = shift;

    my $result = $self->_file_find->next_obj();

    my $last_result = $self->_last_result();

    if (! $last_result)
    {
        $self->_add({ type => "dir", depth => 0 });
    }
    elsif (! $result)
    {
        $self->_up_to_level(-1);
    }
    else
    {
        my $i = 0;
        my $upper_limit =
            min(
                scalar(@{$last_result->dir_components()}),
                scalar(@{$result->dir_components()}),
            );
        FIND_I:
        while ($i < $upper_limit)
        {
            if ($last_result->dir_components()->[$i] ne 
                $result->dir_components()->[$i]
            )
            {
                last FIND_I;
            }
        }
        continue
        {
            $i++;
        }

        $self->_up_to_level($i);

        if ($result->is_dir())
        {
            $self->_add(
                {
                    type => "dir",
                    filename => $result->full_components()->[-1],
                    depth => scalar(@{$result->full_components()}),
                }
            );
        }
        else
        {
            my @stat = stat($result->path());
            $self->_add(
                {
                    type => "file",
                    filename => $result->basename(),
                    mtime => strftime("%Y-%m-%dT%H:%M:%S", localtime($stat[9])),
                    size => $stat[7],
                    depth => scalar(@{$result->full_components()}),
                }
            );
        }
    }

    $self->_last_result($result);
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-dir-dumper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Dir-Dumper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Dir::Dumper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Dir-Dumper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Dir-Dumper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Dir-Dumper>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Dir-Dumper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT/X11 Licence.

=cut

1; # End of File::Dir::Dumper
