package Win32::Env;
our $VERSION='0.01';

=head1 NAME

Win32::Env - get and set global system and user enviroment varialbes under Win32.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Win32::Env;

    my $user_path=GetEnv(ENV_USER, 'PATH');
    # Limit PATH for other programs to system path and specified directory for 10 seconds
    SetEnv(ENV_USER, 'PATH', 'C:\\Perl\\bin');
    BroadcastEnv();
    sleep(10);
    # Restore everything back
    SetEnv(ENV_USER, 'PATH', $user_path);
    BroadcastEnv();

=cut


use warnings;
use strict;

use Win32::TieRegistry(FixSzNulls=>1);

use Exporter qw(import);
our @EXPORT=qw(SetEnv GetEnv BroadcastEnv ENV_USER ENV_SYSTEM);

use constant ENV_USER	=>0;
use constant ENV_SYSTEM	=>1;

use constant ENVKEY_USER	=> 'HKEY_CURRENT_USER\\Environment';
use constant ENVKEY_SYSTEM	=> 'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment';

=head1 EXPORT

SetEnv GetEnv BroadcastEnv ENV_USER ENV_SYSTEM

=head1 FUNCTIONS

=cut

sub _NWA{
 my $lib=shift,
 my @proto=@_;
 require Win32::API;
 return(new Win32::API($lib, @proto) or die "Can't import API $proto[0] from $lib: $^E\n");
}

# TODO: error/sanity checks for other args
sub _num_to_key($){
 my $sysusr=shift;
 if($sysusr==ENV_USER) { $sysusr=ENVKEY_USER; }
 elsif($sysusr==ENV_SYSTEM) { $sysusr=ENVKEY_SYSTEM; }
 else { return; } # And Carp!
 return $sysusr;
}

=head2 SetEnv($sys_or_usr, $variable, $value)

Sets variable in enviroment to specified value. C<$sys_or_usr> specifies either
current user's enviroment with exported constant C<ENV_USER> or system's global environment
with C<ENV_SYSTEM>.

=cut

sub SetEnv($$$){
 my ($sysusr, $var, $value)=@_;
 $sysusr=(_num_to_key($sysusr) or return);
 $Registry->{"$sysusr\\$var"}=$value;
}

=head2 GetEnv($sys_or_usr, $variable)

Returns value of enviroment variable. Its difference from plain C<$ENV{$variable}> is that
you can (and must) select current user's or system's global enviroment with C<$sys_or_usr>.
It is selected with same constants as in L<#SetEnv>.

=cut

sub GetEnv($$){
 my ($sysusr, $var, $value)=@_;
 $sysusr=(_num_to_key($sysusr) or return);
 return $Registry->{"$sysusr\\$var"};
}

=head2 BroadcastEnv()

Broadcasts system message that enviroment has changed. This will make system processes responsible for
enviroment aware of change, otherwise your changes will be noticed only on next reboot. Note that most
user programs still won't see changes until next run and that your changes will not be available in C<%ENV>
to either your process or any processes you spawn. Assign to C<%ENV> yourself in addition to C<SetEnv> if
need it.

=cut

sub BroadcastEnv(){
 use constant HWND_BROADCAST	=> 0xffff;
 use constant WM_SETTINGCHANGE	=> 0x001A;
 print "Broadcasting \"Enviroment settings changed\" message...\n";
 # SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, (LPARAM) "Environment", SMTO_ABORTIFHUNG, 5000, &dwReturnValue);
 my $SendMessage=_NWA('user32', 'SendMessage', 'LLPP', 'L');
 $SendMessage->Call(HWND_BROADCAST, WM_SETTINGCHANGE, 0, 'Environment');
 print "Broadcast complete.\n";
}

1;

=head1 AUTHOR

Oleg "Rowaa[SR13]" V. Volkov, C<< <ROWAA at cpan.org> >>

=head1 BUGS / TODO

Only first argument to C<GetEnv>/C<SetEnv> is checked right now. Considering that functions work with
Windows registry, more sanity checks should be added to other arguments.

Any limitations of Win32::TieRegistry apply to this module too, because it is used to write all
changes to the registry.

Please report any bugs or feature requests to
C<bug-win32-env at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Env>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::Env

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-Env>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-Env>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-Env>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-Env>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Oleg "Rowaa[SR13]" V. Volkov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
