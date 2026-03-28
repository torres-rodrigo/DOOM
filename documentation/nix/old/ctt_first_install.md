# Timestamps
00:00:00 - NixOS Overview
00:04:05 - Finding Packages to use before install
00:17:26 - Install Begins
00:23:46 - Manual Partitioning
00:34:24 - Generating Our Configuration File for Install
00:39:49 - Finishing Install from ISO
00:40:58 - First Boot
00:41:39 - Login and user setup
00:42:07 - SetFont problems
00:43:28 - Figuring out Installing Packages
00:46:20 - mounting backup drive
00:47:29 - Grabing Backup Packagelist
00:50:24 - Installing ALL the Packages 1000+
00:55:01 - Understanding PATHS and proper XDG Paths
01:02:02 - Install Done - Reboot
01:03:19 - Adding a Desktop Session
01:05:10 - Nix Handles Services VERY Differently
01:07:38 - Fixing permissions on mounted external home
01:09:35 - You can NOT change stuff in /etc
01:21:02 - Cloning DWM Setup
01:22:26 - Titus is dogwater at using elinks
01:27:02 - Wierd NixOS package names
01:31:12 - MINDBLOWING NixOS Overlays
01:40:51 - bin bash errors with it not existing
01:48:37 - Successful Install and Recap

# Transcript

NixOS Overview
0:00
it's time for NYX OS it's been a while actually it's
0:07
been never but I've used the crap out of their package manager and today we will be taking the Venture on them home
0:14
production machine no no VM here no virtual machine we're going full Knicks
0:21
minimal build with dwm kind of like what you see here
0:28
but I've been working a little bit with dwm and we're going to change this this is actually was Peter Jensen's uh
0:35
configuration that he sent me I've been working on my laptop with dwm I really
0:40
really like dwm with its just everything's baked into the the binary
0:47
so you you literally can't screw it up it's impossible to break you can't put a
0:52
bad configuration because it won't compile if you do so I have really
0:58
really enjoyed uh dwm far more than I thought I would
1:04
but using NYX OS as a base is something I've always wanted to try
1:10
it's been there I love the package manager I don't know much about the base
1:15
OS though I know that when we go to search to install stuff like let's say we're going to install Brave
1:23
I know that when you do this like NYX OS configuration you just have a a
1:29
configuration file you just throw all your packages right here and then it just installs them automatically so it's
1:35
a setup once OS and then it just doesn't matter how many times you reinstall it
1:41
just puts everything back so very replicatable I love it I know some
1:46
businesses use it and it does run into it's considered a stable release every six months it it happens so that is
1:55
what's on the agenda for today is NYX OS minimal install with just dwm the thing
2:02
I'm kind of I don't know how it'll end up is how does it do dependency resolution how's
2:08
it going to do a minimal install when it needs xorg and some other things that I
2:14
need to build out there's a lot of things probably for prep work we need to do and I'm going to try and do that on
2:19
the front end before we wipe out Old Rocky Linux Rocky Linux has been great for us it's been a fun experiment and
2:26
I've really enjoyed the structure of it more than I have a lot of other installs I've done but I think it's time to go
2:34
into the unknown uh because I kind of want to start laying out the
2:40
configuration of Nyx OS we've already downloaded you can see NYX OS over here
2:47
let's open it up um I'm trying to think
2:53
did I did I install a file browser on this I can't remember I think I have a bad configuration on my
2:59
file browser or or I just didn't install it let's see which is it
3:05
I don't know yeah it's a bad configuration okay let's just uninstall that configuration shall
3:12
we um we need to sooner
3:17
let's just get rid of thunar and then if we do it yeah sooner is fine now it was a bad configuration it was
3:23
just failing on me that's why it was taking forever to Launch um so let's get thunar up
3:30
and start looking at the downloads we'll create that and then we're gonna get
3:35
kind of our packages so it should be like an all-in-one just knock it out all
3:41
right we're gonna go to images drop it in here so that's going to be NYX OS I
3:46
am grabbing the minimal ISO of Nyx because I don't want NYX installing KDE
3:52
or gnome which are the two desktop that it sets up by default I don't want any
3:58
of those tools actually so I kind of want to pick out what we're choosing on this and I feel like the way to do it is
Finding Packages to use before install
4:07
to create our own configuration.nix file and then grab all the stuff we're going
4:13
to use that would be kind of cool I feel like uh that would be neat Let's
4:18
uh come into probably our images directory media images
4:23
and let's Vim it's a configuration.nix yeah
4:29
configuration.nix and yes oh what is NYX our Nix nil LS
4:39
I mean I imagine it'd be our Knicks Maybe oh cargo's not executable I don't have
4:45
cargo installed now well not does not matter so we're going to copy this
4:50
configuration over to here and then we're gonna just add to these
4:55
packages so for like NYX environment Q
5:01
we have all these packages let's just uh copy this
5:07
paste it here and
5:12
now we're gonna just do a substitute command let's just go
5:17
full file substitute dash dot star
5:24
um and why didn't they grab plus Weyland hmm let's just get rid of that
5:31
and then let's just grab the beginning of these lines we're going to substitute the
5:38
beginning with a carrot and add
5:43
pkgs Dot that sounds good and
5:50
this will be an easy way to kind of past our stuff so we're just going to grab oh man that's so cool
5:57
I don't think we need some of these though I think we'll leave
6:03
next get rid of that'll be there already picon Powershell I'm Gonna Leave most of
6:10
these just in case we want to go to a different configuration like go back to our bspwm
6:16
hmm yeah I think that'll be good now let's
6:21
take a look at what our install packages are dnf list okay
6:28
being for dwm we do have some issues there maybe xorg
6:34
probably xorg is what we're going to have to grab let's see what that looks like what kind of packages xorg oh we're
6:41
gonna have a lot I bet you to grab all the dependencies though
6:47
let's do X in it because X in it would grab all the dependencies and should be
6:52
fine so like an xorg X in it like this would grab so much oops wrong copy
6:59
command so that would grab our xorg which would be what we used to render our display
7:08
and what else we got uh is this using Nvidia no no no this is
7:16
an AMD card in here we're good there what other packages do we have
7:22
Vulcan AMD GPU I'm kind of think we do need Vulcan tools
7:29
let's see about that Vulcan tools
7:34
maybe not yeah no we're gonna leave that off
7:39
how does NYX what is what does NYX do for
7:45
virtual machines has anybody run virtual machines and Knicks that's a question I
7:50
have for chat yeah because I use qmu with vert manager
7:57
right now and that would be pretty awesome NYX can be both a stable and a rolling release
8:03
there's an unstable version of Knicks much like Debian unstable and then there's a stable version of Nyx so you
8:09
can actually do both we're doing obviously the six month stable it'd be like installing a Debian bookworm
8:15
yeah there should be qmus must have so we'll see how NYX does with virtualization let's see qmu
8:23
yeah qmu is going to be there I want to see how it does with
8:29
dependency resolution so let's just do vert manager because vert manager should uh
8:34
should kick up quite a few different dependencies with that uh let's just
8:40
grab vert manager da we'll put that into our NYX
8:47
configuration as well all right I imagine we do probably should put qmu in there as well too
8:54
just just around the bases qmu yeah that's
9:00
such a simplistic virtualization package that doesn't make any sense not to
9:07
so right here let's just put packages qmu okay moving on right now I'm just
9:14
looking at all the packages that are currently installed on my system we're going to just try and grab most of these
9:20
from Nyx should have unzipped in here which I
9:25
don't see so let's grab unzip because that's a package I'm going to need
9:31
yeah packages on zip I could have guessed that uh
9:37
so we got unzip uh thunars usually what I use for my package manager funar is
9:43
probably just going to be thinner yeah xfc okay it's a little different glad I looked that up I would have put
9:50
the wrong thing so let's put xfc thunar tldr is such a
9:56
clutch tool I have used that to death I absolutely just adore tldr
10:03
it's so much better than using man or uh dash dash help
10:08
uh it's it's once you've once you've started doing tldr you just can't go back
10:14
so there's tldr probably should do tiny PNG and set that up as well
10:20
just because I do use that for conversion when I'm making a an article on Chris titus.com
10:28
this just looks like all of I don't know what text live is but there's a lot of it
10:33
hmm [Music] I'm pretty sure probably NYX uses system
10:38
D I'm kind of want to design a system with you know open RC or in it d
10:46
uh I really miss that especially since the last stream we were really working on like Alpine Linux a little bit we
10:54
installed that that's just it's fun that's just fun in in general to do let's grab lutras and then steam as well
11:02
from here so we just this package is Steam for that and then lutras I imagine it's just
11:09
lutras other couple different variants of lutras yeah continuing on
11:16
there's a lot of garbage in this that I installed hence it's not very much a minimal
11:22
system uh uh there's all our rusts good night how
11:29
much rust did this install all right let's uh um it's just a lot of packages I don't
11:36
want to scroll through all of it forever so we're gonna just go we're gonna just do it uh dwm install on
11:44
this NYX OS we can just grab dwm just so it grabs the dependencies
11:53
so we're gonna be obviously building dwm anyways but we can use the install just to grab
12:01
any dependencies dwm might need we've got xorg which is the big thing we've
12:06
got dwm I've kind of waffled offline going between display managers like light DM
12:15
or sddm for the boot process and auto login scripts or just modifying Getty
12:21
the login service to just Auto log in the user I kind of gone back and forth I see the
12:27
benefits of both and at the end of the day I think I like the most minimal approach which is just modifying Getty
12:34
to Auto log in and launch everything through an X init script like you see down here with the
12:40
xorg X in it I feel like that's probably the best solution so we have that uh
12:47
let's cat our Etc FS tab you can see that's what we're rocking our home
12:54
directory is set as a volume group on lvm and we got a lot of different stuff
12:59
going so we're gonna wipe out boot boot EFI and
13:05
the localhost live swap file as well and live root
13:11
so let's just copy Etc FS tab to Media images
13:20
I feel like this actually should probably go to home but um
13:25
let's also copy this to um Titus do we have like backups
13:31
because I still need to clean up my backup my own directory is getting ridiculous I have reinstalled so many
13:37
times my home directory is just become Bonkers um
13:42
but that's okay backups okay yeah let's just overwrite that all right
13:49
greatness I think we're ready now the new
13:55
you'll see the new dwm I'm not quite done designing it but close very close
14:03
but let's start our install on this system Dynamic window manager is what dwm
14:09
stands for it's a secless tool you have to compile it you can't install it through a package menu I mean you can
14:15
install it for a package manager but that's just like the base config it's not uh not as fun
14:21
yeah we're going full Knicks at last exciting times are ahead of us
14:29
Mark Market on the stream here 33 33 is
14:35
the time for Knicks to finally happen did I put it where did I put it
14:43
I think this is where I put it oh yeah hydrate important that's kind of funny I just noticed all
14:50
my Arch Linux it's like once a year in January I'm like let's reinstall Arch
14:57
that's kind of funny I just noticed I haven't cleaned that up and all of them
15:02
are in January except right here that was not January I think it was probably when I was doing architis back in 2021
15:08
that's funny all right let's go to Nick's Nicks where are you at nix oh no
15:15
ah man I forgot I forgot something
15:20
uh that's that's not what I meant to do Ella yeah probably need to do that I'm
15:28
back when I pretended to be an arch user hey people are still salty that I I stopped art although I got my art shirt
15:36
on today [Laughter] uh I still pretend to be an arch user
15:41
from time to time depends if you catch me on the right day
15:47
there is nothing wrong with Arch if that's you if that's what you know that's what you like then
15:54
that's what you like um we're gonna go back into our Rocky install one last time
16:00
because we forgot to uh copy that ISO over I've Loved You Rocky Linux you've served
16:08
me well but it's time so we have this
16:13
let's go into our images where did I put Nyx
16:19
oh I need to fix my collating on the next system I hate it when they don't properly alphabetize caps in lower case
16:30
um NYX OS minimal there it is all right and Vin toy yes I forgot to put next
16:38
there okey dokey and oh did I put the Nyx configuration over
16:44
there too let's grab that why we're here did I not save that file
16:50
oh crap oh it's under configuration next okay my bad
16:56
all right let's grab that and put that in Vin toy so we can easily access this stuff uh
17:03
now I'm thinking about it in my home folder I have a backups let's grab that FS tab as well and toss
17:11
that on Vin toy just so I can refer to all those map drives
17:16
oh one other thing we're going to be missing from NYX config oops oh well
17:21
whatever it's fine let's reboot away we go
Install Begins
17:27
it's happening for real this time it's a false start but that's okay come on boot menu did I get
17:34
it yes yeah I did Ashlyn as far as getting the message you sent uh about installing any
17:42
Windows uh thing using that GitHub project I went ahead and went back to the video clip I made from a live stream
17:49
in the past and copy that I gave you credit for it too to Ashland thanks so much for sending that over that's gonna
17:55
help somebody that's looking to install an old version all right NYX OS here we go
18:02
all right looks kind of like an arch setup that's interesting NYX OS help ah NYX OS help
18:12
okay oh they got a little manual well isn't that sweet installing
18:18
okay now we did do the manual setup because I didn't want to do uh didn't want to do it the easy way
18:26
I like I like making my life hard that and I want the most minimal setup here too
18:31
uh let's see sudo-i so you can load keys and switch
18:36
your keyboard profile set font we should probably do like a set font or 22 probably
18:42
we can do that okay so partitioning and formatting
18:49
probably should have read this before uh before launching it but that's okay
18:55
hmm okay UA Phi create a oh dang
19:02
everything's super manual all right it feels like I'm installing arch for the first time again
19:08
back before they had the what are the calamares install tool that's awesome
19:14
okay once a primary GPT partition make partition primary
19:24
yeah you can go with the graphical ISO but I don't want all that bloat I don't want to install gnome or KDE so that's
19:31
why I chose this method interesting so how is it loading it so
19:37
you go ahead and partition everything you got your swap you have your primary and that's it yeah so you're just
19:44
creating a partition table a root partition a swap partition and then a boot partition which is in the dash boot
19:51
partition so I like that setup so that's using ESP
19:57
let's see it's an interesting way of doing it probably will just use G parted I kind
20:03
of like G part it better than parted um ESP
20:10
et32 one Meg 512 set three ESP on yeah all right then you
20:17
got Legacy which is fine we got formatting wow oh this kind of
20:25
kind of reminds me of that we're gonna have an interesting go at it I'm gonna forget all this it's been so long since
20:30
I've done a manual install like a true manual install and then you do the install after you partition
20:37
all right well let's take a stab at it shall we we're gonna skip the swap though
20:44
uh all right yes all right so
20:52
we're going to first go with suda we'll just switch to super user and then let's go BLK ID let's map out
21:00
what drive we want to use First uh uh okay nvme in one is our Windows
21:07
drive so let's not wipe it out you know me I have a tendency of wiping out everything but uh nvme
21:14
e0 in one is our current drive with Rocky and everything installed we have
21:21
those Dev mappers for the lvms for the Swap and also the live root that you see
21:27
there we need to wipe that out although I think if we just do G parted Dev nvme
21:35
zero in one I think that oh dang it
21:42
can I do like a NYX environment q a g parted oh that'd be cool
21:49
let's try see if I can't like create a NYX environment inside of Nyx OS
21:54
installer tool to use g-parted because I don't want to use parted
22:00
sometimes this does take a little bit you should be able to with Nick shell
22:05
Dash p g parted okay let's try that Nick well let's first go APA do we get
22:11
an IP yeah we got an IP okay so let's try Nick shell Dash p
22:18
I don't have to do Nick's packages anymore it's nice G parted oh oh I'm liking it I'm liking it that's
22:26
so sweet g-parted do we have uh oh I cleared that out
22:31
can't remember was it g parted depth I gotta figure out what the hell is my USB doing but uh nvme e0 in one
22:42
oh not g parted CG CG parted is that it
22:47
no what's the graphic it's like a graphic terminal parted command I thought it was it's not CF
22:55
I think it's just C parted right I know maybe CG parted I think CG parted
23:01
I don't know why I was thinking g-parted let's see if we can just grab CG parted
23:07
is that a thing no I know there's CF parted okay that's
23:12
not there either exit this ah CG parted
23:19
CF parted okay CF part it's definitely a tool okay it's not there hmm
23:25
interesting so it drops into a shell and then you can do configurations with certain ones there's just parted hmm CF
23:34
disk now that's what I was thinking of I'm such a bonehead that's right
23:40
see uh I think it's actually CG disk is what I was looking for maybe it was CF disk uh what oh what if
Manual Partitioning
23:49
I go just see okay that does work it's already there I'm searching
23:55
crazy person all right yeah yeah yeah yeah yeah this is what I wanted it was CG disk uh CF disc is for
24:02
traditional dos Legacy system CG disk is for G GPT
24:08
UEFI systems so we have this and I think does this have format
24:13
commands I can't remember um we have a one gig Linux well I think
24:18
we can just go delete delete and uh EFI system partition EFS all
24:28
right let's just delete that let's go new a partition size let's go 500 m
24:35
uh oh no actually cancel cancel no oh dang it
24:42
oopsies my bad try that again round two all right first sector size in
24:48
sector 500m type of file system code I think it just
24:54
we need EFI there's the EFI partition let's just do
25:00
an l l what was it I feel like there was another UEFI partition too
25:07
so there's e f which would be yeah there's EF zero zero I want to say
25:13
there's another one too I don't think I need it but I was just curious I was just curious on the different ones
25:21
hmm let's just do an l oh here we go continuing down okay so then there's the
25:28
BIOS one which is ef02 which would be a bios boot partition so if you're doing a
25:33
legacy one you'd want to do that obviously we don't so EF 0 0
25:40
would be the hex code new Partition name we're just going to call EFI boom 500 Megs and then
25:48
we're not doing a swap if we want swap we can just do a swap file the difference between swap file and swap
25:53
partition not a whole hell of a lot a lot of people give all this credit to swap partitions being like infinitely
25:59
faster or something but in testing I have not seen almost any difference between a swap file and a swap partition
26:07
interesting tidbit so why why bother gunking up your partition table with the swap partition is what I say
26:15
um what kind of file system do we want just do Linux file system
26:22
root alrighty let's write that out sounds good to me
26:29
we'll destroy all the data yes all right we're done
26:34
uh what was the next step was it just like Nyx Dash install
26:40
okay uh oh NYX OS Dash install
26:45
uh NYX Mount Etc doesn't exist
26:51
interesting probably should look more into that help
26:57
file was it NYX Dash help I can't remember what we were using try Nix OS generate
27:03
conf into mmt okay so how Arch Linux does it
27:09
from here is it uses it's Pac-Man and you're you're you mount
27:16
the file so you probably would have mounted the file system before this because if you go into
27:23
let's just do it let's be okay just to get kind of a readout of our file system you can see here
27:29
what we're doing and you can see our
27:34
oh that's wrong why is this not reflective of our partition changes
27:41
huh we did wipe that out did we not it does not look like we did
27:47
I don't think it accepted our rights hmm
27:52
let's reboot let's just uh I'd hate to what the hell did I wipe out then
28:00
that's a unfortunate oh yeah yeah let's increase magnification so you all can see the
28:07
mistakes when I make them all right let's go Knicks oh what what is going on here
28:17
I only downloaded the minimal installer hmm that's interesting okay
28:24
next OS Dash help or if we get lost again uh I wanted to do that blkid
28:30
uh let's switch to City Uber be okay ID couldn't read it all okay it is now
28:36
reflecting the proper partition scheme that we set up it just needed a reboot we probably could have like
28:42
re-initialized the drive uh somehow and then had it reread it but you can see
28:48
our partitions are there and those lvms did get wiped out so if this is like Arch if we go into
28:55
mmt there's nothing there and if we do like oh let's do set font tur V 22 in
29:03
yeah let's get that a little bit clearer for you guys all right so this is what we're working
29:09
with um and I didn't wipe windows we actually
29:15
did it right and if we look at the partition layout right now we want to write the install to nvme e0
29:25
in one so I'm guessing here let's just see if my guess is right let's do like a mount
29:33
Dev in vme 0 1 in 1p2 M into the mount directory
29:41
like that wrong file system so probably the issue here is we've we
29:48
didn't format these things oh gosh formats uh it's not format it's a make
29:56
FS Dot fat oh God bless I can't remember exactly
30:03
what was it make FS dot fat I want to say f
30:11
32 and then we would do Dev in vme e0 in one p one
30:20
I don't hope that I don't screw this up uh and I believe that just formats it right is there a quick format option I
30:27
don't think there is okay I think that should have worked and then
30:33
make FS Dot um we could do better FS
30:38
yeah well let's not confuse ourselves let's just do an ext4 can't remember the options for ext4 I
30:44
don't think there was much I want to say I just do like a nvme 0 1 n1p2
30:52
something like that oh do I need to specify that as a
30:58
bootable one on that partition uh make FS dot fat was there a bootable
31:05
option Dash in is what they said yeah maybe not I think I got it
31:11
the partition itself might need a boot flag I can't remember I know I think on
31:16
EFI we don't how do I mute stream elements I don't
31:22
think you can mute it okay well let's uh try that mount command one
31:28
more time so there we go and then what we do is
31:34
like boot and then we do P1 oh I need to update
31:39
the schedule yeah because we're doing Tuesday Thursday now uh does not so I think we just do make
31:46
directory boot and then try that again all right so now if we look at our Destructor directory
31:53
structure this is a typical Linux install I'm guessing here so you know what you see here at the bottom you
32:00
should see that nvme e0 n1p1 that's our EFI one is is mounted to dash m t Boot
32:08
and then the root where all the data is pretty much stored is M and T
32:14
there's one more here the lvm the vg1 lv1 that pry needs to be mounted into
32:21
mmt home Titus as my home directory but I like to kind of install the OS first and then make
32:28
that directory yeah all right
32:35
so now we have NYX OS install uh but if when we run NYX OS install it
32:41
says we need mmt Etc NYX OS configuration does not exist
32:47
feel like there's something else we're missing here too let's just do help
32:52
let's go installing the OS again booting the installation media let's go
32:58
manual install let's see what we're missing networking the installer we're already doing DHCP
33:04
it already grabbed it we looked at an IPA we did our partitioning and formatting
33:10
uh we could have done the in boot that's
33:16
just a label though we can come back it's not really important installing so
33:21
the installation Mount the target file in m t yeah that makes sense
33:27
ufi systems you need to do this look at that look at that I guess that
33:33
that's beautiful and next you need to create a file configuration.nix
33:40
that's cool the Knicks generate comp dash dash root MNT then you should edit
33:48
the configuration.nics to suit your needs let's see how far off this is from
33:54
what we did next you must select your bootloader we recommend the recommended
34:00
option system D boot I don't really like the recommended option I like grub if
34:05
you want to use grub set boot.loader.grubdevice to nodev
34:10
and then boot.loader.grub.efi support to True
34:15
okay good to know that's a helpful configuration
34:22
all right neat so the big thing here is generating the comp file with uh root
Generating Our Configuration File for Install
34:28
MNT Nix OS generate that config and then root MNT yes
34:36
NYX OS generate config dash dash root Dash m t
34:42
okay so then we go into we have them oh look at that
34:49
it comes with them already after my own heart here Vim Etc
34:56
Vim Etc ah M and T
35:01
C NYX OS configuration okey-doke what do we have this is neat
35:10
all right so set your time zone we'll go yeah we're gonna go America
35:19
uh Chicago no proxy configurate keymap for X11 nah
35:30
leave it no cups we will enable need some sound here
35:36
pulse audio I wonder if they're using pipe wire or pulse audio I guess we'll figure out
35:41
touch pad don't need Define a user account don't forget to set a password with PSW
35:48
okay kind of neat oh you get to pick the packages here
35:54
interesting okay uh We're Not Gonna Be Alice we'll just call this Titus
36:00
okay this package is installed with system profile Nana oh yeah let's do
36:07
that oh God I gotta get rid of that error message it's driving me crazy
36:13
USB 3 just sucks but oh well uh networking firewall enable false yeah
36:19
we're just gonna disable it disable it for now copy NYX OS
36:24
configuration file link it with resulting this is useful in case you accidentally delete the configuration
36:30
file yeah I guess I could see me deleting the system configuration file
36:36
let's be real pretty sure that's the end of the config it's pretty simplistic
36:41
so we're doing LSB okay Vin toys Dash ISO if we cat or let's do
36:50
an LS dot ISO oh I don't have
36:56
all my configuration from there darn it I don't think I can mount that
37:01
either because of how Vin VIN toys set up that's okay
37:07
if I was smart I would have put it on a different disk but I'm not smart I didn't so
37:15
I will just have to rely on the stock configuration and then see how
37:21
can we we'll figure out how to rerun that um one other thing I'm just seeing on
37:27
the bottom here I guess we'll do let's just do system EFI system D we'll try and change that
37:34
after the fact that should be fun enable X11 windowing service yes we do
37:41
want X11 us X server we're not going to change that
37:47
one other thing here let's get rid of that um
37:52
you know I think we could actually set this up as like Brave instead of Firefox Nic search environmental packages
38:00
so just Nick's command I like it some programs need suid wrappers can be
38:06
configured [Music] um services pretty Bare Bones all right now I feel
38:13
better yeah I could disable the stream elements
38:19
it's bothering you too much once I get everything set back up here hmm
38:24
all right so if we look at we generated the
38:30
was it help let's look at this one more time and
38:36
we're just flipping through looking at our install so now that we've got the configuration
38:42
we didn't really change anything from the stock just like instead of Firefox and Thunderbird we're just installing
38:47
Brave we're going to do a NYX Dash or next NYX OS Dash install
38:52
it would set the root password or root user which is fine
38:58
man that seems so simple I feel like that might not work you should now be able to boot into Nyx
39:05
OS every time you change the configuration you should log in and change the root password or password WD
39:11
you probably want to create some user accounts as well this can be done with user ad which I think that was actually
39:18
part of the configuration.nix we'll see if Titus gets created or not
39:23
and this is the summary yeah that's slick I'm good documentation
39:29
goes a long ways is there some things you definitely would get tripped up here
39:34
um the bootloader grub device example configuration
39:40
I don't think we need that though so we should be fine that's fine
39:45
We're Not Gonna over complicate it we'll figure it out afterwards so NYX OS install
Finishing Install from ISO
39:51
let's see what happens all right building the configuration yeah I'm curious to see all the
39:57
different paths we can take here what are the odds we'll be able to reinstall our stuff
40:04
I'm kind of looking at the packages it's installing it's grabbing a good bit a lot of
40:10
libraries we got Nick sudo there's our X tools
40:16
the drivers I suppose units price system D units looks like
40:23
installs X screensaver I still love the Gibson model from X screensaver still one of my favorite screensavers of
40:29
all time system D and UW rules it is installing pipe wire I was
40:36
wondering about that created all the EFI stuff looks like it's good now let's set up
40:44
our root password password updated so we take a look at our oh it unmounted
40:51
unmounted at all okay so let's reboot and see if we get uh NYX
40:57
OS installed properly don't know if it actually installed my user though that's that's the question
First Boot
41:03
oh you know what the user's not going to be able to log in because I didn't set a password so that's that's a problem
41:09
all right let's see what NYX OS looks like all right
41:15
there it is okay what did it install
41:21
oh there's nothing I was like I didn't install a desktop environment it's like nope you sure didn't
41:28
it does look like it's using this looks like light DM where's this
41:34
gnome now I think that's light DM all right fine
Login and user setup
41:39
TTY yes there's TTY let's go root password did it create the tightish user
41:47
okay it did nice uh let's set our font right
41:53
uh oh set font ter V 22 in
41:59
unable to find file hmm all right how do we install stuff we
42:05
have NYX what's the Nix command do I've always wanted to use the Nyx command
SetFont problems
42:10
we got examples look at this hmm NYX build
42:17
tool for building a software blah blah blah sub commands oh it's set faunter
42:25
let's just see what we have available on set font oh set font dash dash help usually it gives you files are loaded
42:33
from the current directory Etc kbd console font ah okay what do we have to
42:41
choose from here set font hmm I guess we don't have any uh we need to get Terminus fonts going
42:48
for sure uh we'll use like uh I'm thinking lat two Terminus 16
42:54
probably would be good I want a little bigger though do we have anything bigger than that
43:01
hmm well a lot of small fonts to choose from
43:09
I guess we could use a sun font I mean Sun 12 by 22.
43:16
it works it looks a little weird but once uh we'll uh we'll address that once we get
43:24
some better fonts installed hmm so
Figuring out Installing Packages
43:30
how do we install things these are things you probably should look up before doing NYX but
43:35
where's the fun in that so we have Nyx shell which builds it in a shell
43:43
there's NYX environment which creates its own environment
43:50
but since we're using NYX OS we should be able to just put it like NYX OS Dash
43:55
install kind of thing but that's how you install the system all right let's go see how their help
44:02
file hmm um there is no command for this
44:09
so I guess the big thing here is um how do we install
44:16
the first challenge and why does this USB 3 Port 1 keep
44:24
popping up oh my gosh guys driving me nuts
44:30
ah sorry how we do have the Nix configuration do
44:36
we have them okay great we do have them so if we go Vim can fit them
44:43
Etc um Nyx is it NYX OS mix OS
44:50
configuration all right we have this so if we change this does it
44:57
automatically just update the system questions full Nicks okay now this is where you
45:05
make your changes and then you just run a NYX rebuild switch it can't be that easy right
45:10
Can it can it be that easy that feels too easy so you have the system packages
45:17
right here so what if we do like a dwm
45:23
we'll use like the stock dwm until we get our I think Braves already
45:29
installed so we have vimw get dwm and brave uh we also need like neofetch neofetch
45:37
so then we do Knicks OS rebuild switch
45:44
oh wait ah dang it NYX OS Dash rebuild switch
45:52
building Nicks building the system configuration is it gonna
45:57
okay that seemed fast oh
46:03
okay it worked cool that is super cool all right so I bet
46:10
you if I remember right the package oh here's what we're going to do wait oh
46:17
you guys are gonna like this you're gonna like this a lot uh let's grab that VIN toy package SDC one it looks like
mounting backup drive
46:25
let's uh do a mount Dev SD SDC one M2 M and T
46:33
uh make directory M and T what Mount Point does not exist
46:42
hmm oh what the hell where am I I'm in root uh
46:52
uh that's funny okay yeah let's just come into here all right
46:57
let's look let's go make directory MNT now and then let's do our Mount that was
47:03
funny okay so then we go into Mount and we should have that configuration.nix perfection
47:13
it's about to get real up in here that'd be so cool uh
47:19
NYX OS configuration all right we did that to make this
47:27
magical magical thing happen we're going to retrieve a cat of m t forward slash
Grabing Backup Packagelist
47:33
configuration Nyx compliance oh wait wait we don't need
47:39
this don't need that let's just get that rid of that
47:45
um I'll just grab these guys substitute pkgs dot dot to nothing
47:55
alrighty and fix our indent oops wrong indent
48:01
end it that way oh no ah I mean it's not the end of the world but let's let's fix that
48:10
oh I forgot the default Vim kind of sucks oh well
48:16
why did I have alacrity in there was that alacrity uh it was
48:21
let's switch that with Kitty I know the indents wrong chat but we're gonna just rock that all right great so
48:29
now we're gonna go NYX OS rebuild switch
48:34
aha Oh shoot what GitHub oh
48:39
github's not a valid package I'm probably it's probably like GitHub CLI or something
48:45
G settings why do I have G settings weird not a valid package one more time
48:53
third time's the charm okay maybe fifth time's the term one second uh papyrus
49:00
and I had a whole bunch of packages that don't exist all right xdgs next
49:08
all right yeah all right now this is gonna work
49:14
all right oh it doesn't like to install Steam
49:20
because of uh non-free by default for NYX OS rebuild you can set Nick's
49:27
packages allowing free in the configuration next on where do I put that
49:34
ah nixpackages dot config allow unfree
49:40
that's like camel case I suppose okay where would I put it I imagine beat
49:46
towards the top right these are Imports and if I was importing something I'd probably put it up now
49:54
that's an import variable hmm alrighty should be in
50:01
so where do I put it though anywhere in the config file is fine that seems wrong
50:08
literally anywhere really okay well let's just put it at the top
50:13
well don't forget the camel case true and I always forget the semicolon
50:20
but that should be good alrighty Nyx
Installing ALL the Packages 1000
50:26
rebuild switch yeah it seemed to work I bet steam's gonna grab quite a bit this should grab
50:33
almost any kind of graphic thing we need I don't necessarily like let's say I'm not going to use Steam on here I still
50:38
kind of like to install it if I'm playing games on this system which obviously I'm I'm kind of a gamer so I
50:44
kind of want to check it out man it's so cool so far though it might be my
50:49
forever distro I don't want to jinx it it's only been an hour but it could be my forever distro I really
50:58
like its design like it feels Forward Thinking
51:05
[Laughter] it it did yeah we'll see we'll see
51:13
uh yeah stream steam will grab wine as well
51:18
his wine will be needed for proton man it is building a lot though I did
51:24
put a lot in there I just kind of wanted the base packages uh what do you guys think the package count will be because
51:31
at the end of the title of the stream is the most minimal install what are we thinking with steam and all
51:38
those 32-bit libraries obviously we're going to be a little more bloated than a true minimal install but this is like a
51:45
minimal Linux gaming install really 69 I like that I like that I'm surprised we didn't get a 42.
51:52
690 packages 500 ish man that seems awfully low
51:58
because we are using steam with the 32 paper I'm going to say a thousand
52:04
yeah I'm saying a thousand will probably be it because when you install Steam it
52:09
immediately installs probably at least 300 packages because all those 32-bit
52:15
packages bloat things up but can it run crisis we're about to
52:21
find out I think steam does have a built-in browser as well believe it or not I I
52:26
don't know uh we'll see what it ends up doing if it was going to do a make I wonder if
52:33
there's a way to speed this up with a thread count I mean it's not going slow it might be already using Max threads
52:40
actually this is going pretty quick yeah this is my main machine Rocky is
52:46
gone NYX is the new the new operating system of choice I've never used NYX so I was like I love
52:54
the Nyx package manager so given my love for the next package manager the OS has
53:00
to be like even better right that was my thought process going into today Rocky lasted one week I think it
53:07
was two weeks that's a pretty long time in in my world but I love so what I hate is when you go
53:15
to install like a new distro and it's like holding your hand and
53:21
it's just more of the same like I love the thought process in the
53:28
out of box thinking that went into Knicks especially when it comes to automation like once you get this NYX
53:35
file built you can literally just throw it on a new system and go here here chat you want to install
53:42
everything that you saw on the stream I'll give you my comp configuration.nix file you pop that
53:48
configuration Nix file into your system go and do these type things it will
53:54
replicate my system one-to-one for you you're not going oh crap I forgot this
54:00
dependency or I need this it will be everything on mine
54:05
no other Linux distribution has that you can create scripts you can do other things to kind of replicate it but that
54:13
has so much human error where this is is the package in the configuration.nix file yes
54:19
it gets installed that's pretty legit
54:25
but yeah yeah there I'm sure there'll still be some changes especially when it comes to the dot configuration files so
54:31
when we get into building out like
54:36
um I wonder if we could automate this I bet we can because there's there's a lot of packages and nicks that are really neat
54:43
but I really think grabbing like my DOT files
54:48
and some there's going to be other little gotchas but they'll be pretty minimal so you get like my dark theme
54:55
so I probably would throw everything in I'm going to redesign how I'm doing my
55:00
DOT files there's two things on my DOT files I'm thinking of just for replicating this
Understanding PATHS and proper XDG Paths
55:07
dot local share and going to a an xdg correct format so in the past I've
55:16
thrown fonts and themes and other stuff into home dot fonts and home dot themes
55:22
that's actually incorrect that's a bad practice hopefully nobody looked at me
55:27
and copied because that's not exactly the way you should do it what you should do is put that xdg into
55:36
dot local forward slash share forward slash fonts or forward slash themes in
55:43
that directory that's where xdg which is what like determines your default uh
55:49
terminal or your default uh folders or your default path that's going to show
55:55
up in your start menu or whatever uh that's kind of how that works and that's probably where we should do all
56:02
of that and that'll also make it very nice for when you go into like a flat
56:07
pack that's where flat pack will look because it uses the xdg standard as well so it'll be your flat packs will act a
56:14
little better too from past things so I'm just thinking through all those little things to where if we just copy
56:21
the dot config and the dot local and then toss that in a new install
56:27
that'd be pretty awesome oh yeah I need to look at flakes flakes will be interesting
56:33
or you could set the appropriate xdg environment variable we could probably set some of those xdg environment
56:39
variables in our DOT profile which X in it should also run on Startup
56:46
now the next thing I want to kind of see how we modify NYX a bit here too I'm
56:52
curious to see about modifying Getty and then how it interfaces with X in it be
56:59
kind of cool yeah I mean you really don't need flat pack for NYX even though it probably
57:04
would work like NYX has pretty much every package you possibly could want
57:10
flat pack since Snaps are the double you've been watching too much Chris Titus Tech
57:16
uh oh man where was I the other day I think I was like on a Linux meme subreddit and
57:23
I was reading and my name popped up but I looked at it I was like oh that's unfortunate and it was uh I think some
57:31
pretty jaded vets are probably the Arch Linux crew because I often don't speak highly of arch even though it's it's a
57:37
good distro you know I still love arch for what it is and they they're like yeah that Chris
57:44
taught us Tech he knows servers but he doesn't know anything about Linux desktop but I'm like
57:49
okay [Laughter]
57:55
at the end of the day everything's like based on Linux server like you can
58:01
literally do anything in the CLI how is knowing like a gooey tool in
58:07
Linux gonna help you I I don't understand that like that was a weird
58:13
comment and then it got like a whole bunch of upvotes and I'm like wow okay that's enough internet today for me
58:20
you know this the flat pack versus snaps debate uh it's always interesting I mean
58:25
I'm getting to the point where I'm like I just don't think either or a true solution I think flat pack is better
58:31
than snaps but still a substandard solution in my opinion I still would hate to install more than
58:37
10 flat packs on my system there's a couple of things where I I
58:43
sacrificed that belief a good one's like a mutable file systems you pretty much have to use them like if
58:50
it's an immutable file system you put it anywhere but your home folder that's gonna get wiped out by the way NYX has a
58:58
utility that creates a package for an app image URL that's cool
59:04
yeah I can't wait to dive into some more of these Nick options between flakes the
59:09
shell if you need like a sandbox version you can do that through I believe it's
59:15
Nick stash shell you can do special environments with Nixie and V and that's how it's done on
59:21
other systems which I've been messing with that's kind of how I've always used Nick's package managers through a NYX
59:27
environment so man so many cool little things God bless how long is this gonna take
59:34
oh you can even redirect your configuration file with the switch and
59:40
then the dash l command okay
59:45
yeah I've noticed that too lab and I've actually done like a NYX environment in a specialized directory when installing
59:52
mix on the steam deck so I use the Nyx packages on the steam deck uh
59:58
I think I even had to do a separate user base systemd service to to adjust things a
1:00:05
little bit so on Steam updates it wouldn't wipe out my NYX packages because I had to switch it from the the
1:00:11
root NYX package directory to a home NYX package
1:00:18
directory that was a little bit difficult to to put in but once I got that in NYX is working great on a steam
1:00:24
deck and that's nice because then you can install anything oh is that a pipe not an L okay
1:00:31
or no I and I I'm sorry that's yes Dash I uppercase i okay
1:00:39
that's funny uh I as an information
1:00:45
well I also have like my chat on like a super small screen up here although I will say the new new desk configuration
1:00:51
with the up and down monitors I love it so good
1:00:57
for stable and up-to-date software gaming would you say go fedora
1:01:02
oh Ah that's a hard one I mean if you don't really want to mess
1:01:08
with your system very much I've recommended nubara in the past which is based on Fedora
1:01:15
and the reason why I say that because glorious egg rolls probably probably the de facto standard when it
1:01:23
comes to Linux gaming like he just knows his stuff and he makes nubara and he
1:01:29
chooses so many great defaults way better than 99.9 percent of the users
1:01:35
out there so if you're doing a lot of gaming on Linux I would say
1:01:41
nabaro's really what you should install it's gonna have the best defaults it's gonna have the best compatibility and
1:01:47
that's because glorious egg roll makes it and he's the guy that makes like proton GE
1:01:54
GE means glorious egg roll and uh man it's it's really good
1:01:59
okay that was a lot of packages neofetch what are we at yeah oh
Install Done - Reboot
1:02:05
1585 packages all right
1:02:11
yeah thanks Michael yeah I'll be sure and remove the stream elements if it gets annoying I kind of imagined it
1:02:17
would be like that so from here we should have
1:02:24
dwm not really hmm that's okay
1:02:29
we'll just drop into TTY too um what do we have for our home folder
1:02:39
you know what I'm gonna do here let's
1:02:45
there's nothing in here right now and it's under Titus users those are groups users and wheel
1:02:52
let's just Mount our old volume group um I need to check to see if there's lvm
1:02:59
command what would that be maybe do we have git dang it do we have to do
1:03:07
a rebuild every time we want to install a package I guess you do uh it gets annoying I guess when first
1:03:14
setting up a system but still not bad oops
Adding a Desktop Session
1:03:20
yeah we're probably missing mini xorg the dependencies probably did not quite get there
1:03:26
oh that's right you need to move it from your packages and add this
1:03:31
Services DW oh okay wow this is so weird okay
1:03:38
so we have X server enabled true so then we would do
1:03:43
Services dot X server Dot Window Manager dot dwm enable
1:03:53
equals equals true I know true interesting
1:04:01
when you want to permanently install it yes although you can just do a Nick stash LP get to get a temporary shell
1:04:08
does that shell get destroyed when you exit it that'd be interesting
1:04:13
you can do it with an unstable okay yes it gets destroyed so if you do just need a one-off command uh next Shell would
1:04:22
just install it interesting that's cool all right so let's come here
1:04:28
I'm sure this is just like a get and then Nick's OS rebuilt whatever
1:04:37
oh man my history is getting wiped out switch uh I I need to reinstall my bash
1:04:44
anyways it's all good
1:04:49
oh it did not redo my history I was in my user
1:04:57
yeah that's a problem okay so now we have that what if we go back into
1:05:04
wait was it tty7 yeah still there yeah so
Nix Handles Services VERY Differently
1:05:10
let's before we reboot what if we do like a pseudo system CTL restart light
1:05:16
DM is that not light DM does it handle system D services
1:05:22
differently is it even using system d what did I miss the services are handled by Nix
1:05:30
so interesting Noah's is going to be a little bit of a mind F right here
1:05:36
because system d you can't interact with it directly
1:05:42
because the services are somewhere else okay let's take a look
1:05:48
system CTL dash dash all ah let's see I'm looking
1:05:56
there's a Getty service I swear that's light DM is it not
1:06:02
because I don't see that so strange
1:06:07
there's not very many services here hmm you have to set it in the configuration
1:06:14
huh what bookmark manager are you using I don't I don't know what you're talking
1:06:20
about on the bookmark manager all right let's reboot so everything's in configuration.nix
1:06:27
means more reboots and but that's okay once it's set up it's set up it can't really break it
1:06:33
sounds like a challenge to me [Laughter]
1:06:39
all right um there is none plus dwm let's see do we
1:06:46
have yeah okay all right
1:06:51
um oh what is the default binding for D menu oh I didn't install demon you
1:06:58
okay crap what are the default bindings on
1:07:04
dwm yeah we didn't even install St now
1:07:10
man that's okay TTY TTY to the rescue
1:07:16
anytime you get in trouble the beauty of Linux is you can just say you know what
1:07:22
give me the console I will just fix it myself
1:07:28
um I did want to mount this so let's come back one we're gonna go
1:07:36
into super user mode all right we'll have Titus Titus we're going to copy Titus to Titus Nix
Fixing permissions on mounted external home
1:07:44
uh we're gonna have to do a recursive on that and then we're gonna Mount that FS tab
1:07:55
let's just remove Titus
1:08:00
and then what we're going to grab is the LV oh shoot
1:08:07
lvm guys the lvm is going to be a problem I don't think I can mount the lvm
1:08:15
oh cool it installed LV by default oh nice that's clutch
1:08:21
yeah oh so nice so nice of it Dev
1:08:27
bg1 yes okay
1:08:32
I think on this one I can just do a mount the vg1 lv1
1:08:42
I forget if I have to specify I can't remember I think it was better off fast uh home Titus
1:08:50
I make directory tennis CD Titus
1:08:56
oh crap okay backpack you mount um Titus
1:09:03
um this actually needs to be a mount just home
1:09:09
then we do a list oh boy all right there's all that
1:09:15
uh uh I wonder if it's gonna mess with my Knicks that much now we'll figure it out
1:09:21
uh pseudo Vim Etc FS tab
1:09:26
so this does work and uh let's just
1:09:31
oh really oh I needed this wait what can you not change why is that a read only
You can NOT change stuff in /etc
1:09:39
it's immutable isn't it ah shoot yeah yeah I know about searching packages on NYX this is the first time
1:09:46
I've used NYX OS and there's a lot of nuances to this OS to make changes oh it says it right in
1:09:53
the readme read Chris uh to make changes edit the file systems
1:09:59
camel case or and swap devices in Nix OS options in your Etc
1:10:05
ah poop joking what does that look like
1:10:10
as with everything it's in NYX OS configuration
1:10:17
okay copy system configuration file okay list packages you want to installed
1:10:24
configuration file is there no files okay so we just kind
1:10:31
of have to guess on the syntax here ah poop all right how
1:10:37
we gonna do fstab all files in the next door are immutable hmm
1:10:43
oh that's fresh RSS uh for checking the news by the way guys
1:10:48
um all right let's go to the help file
1:10:54
Nick's help NYX OS help please help me NYX I don't understand oh
1:11:01
that's right we gotta get uh probably w3m or e-links I I've used e-links a whole
1:11:07
bunch in the past uh w3ms kind of the one I want to go with though
1:11:12
back to our HTC next w3m [Music]
1:11:19
all right now we'll just do a NYX OS rebuild switch
1:11:25
so odd kind of like it getting still wrapping my brain around this
1:11:30
but I really I enjoy it I really do like it
1:11:36
it's not bad but NYX OS help
1:11:44
aha there we go so we get changing the configuration file systems
1:11:51
what do we have here yeah I can't even open up a browser yet because I I have a stock dwm install and
1:12:01
I need to I can clone I think we've rebuild my dwm with my my dwm I have
1:12:09
it'll make this way easier I'm overthinking it but
1:12:15
I wonder if this tabs we have encryption that looks like a fun
1:12:21
time luckily nothing's encrypted here okay interactive mounting
1:12:27
a non-interactive mounting dude this is so so strange for me
1:12:34
so you have your device type for non-interactive mounting
1:12:40
oh damn um whoa this is I'm gonna need a GUI for
1:12:47
this this is going to be wacky uh let's just grab our our home
1:12:54
directory I'm not going to try and grab our our NFS shares yet oh boy so for this one
1:13:02
oh oops nope its device the device
1:13:08
the dev path and then file system type that should get me what I need how do
1:13:15
you determine where it gets mounted though you can Define file systems for instance
1:13:20
the following definition causes Nix OS to mount the ext4 file system into onto
1:13:27
the mount point forward slash data okay forward slash data so you put the label
1:13:34
and then that's kind of Jank
1:13:39
this will create an entry in FS tab corresponding to the Mount system FS tab
1:13:45
generator blah blah Mount there no Auto
1:13:51
can be changed Mount points are created automatically for device it's best to
1:13:56
use a topology independent aliases in Dev by label which is fine so
1:14:04
Deb by you you ID is these don't change probably what we want to do but this is a volume group so it doesn't matter but
1:14:11
don't change it okay that's fine I like that warning it's just weird so
1:14:16
the thing I'm debating here if you go file systems oh I see it now
1:14:24
file systems quotes this is the Mount directory equals and then you do
1:14:29
brackets device and file system type okay I was overthinking it I I missed the
1:14:35
the dot quotes I'm still getting the syntax wrong all right okay
1:14:43
once we get this we'll have our home directory and we'll get to the GUI and things will be right with the world
1:14:49
ah uh oh and we need to install Terminus fonts too because nobody likes super
1:14:56
small fonts [Music]
1:15:02
okay dude oh don't forget d menu yeah yeah D minus needed all right let's go back to
1:15:10
hey we're in this configuration file a lot get used to it if you install NYX I
1:15:15
suppose okay so we have dwm let's install D menu because we can launch
1:15:21
stuff and then we have kitty down there I feel like we should just throw St in there
1:15:27
just in case uh oh actually you know let's go St just to have that
1:15:35
uh the other thing I needed we're doing git the file system paths
1:15:42
I feel like putting it here is fine all right
1:15:48
file system camelcase dot path will be home
1:15:54
equals okay and then do a bracket go here
1:16:03
quotes oh what was it uh device equals
1:16:10
Dev uh volume group one logic volume group one comma
1:16:19
FS type camel case equals [Music] oh geez I think it was better FS
1:16:27
yeah that does not look right to me uh it's not oh that should be
1:16:34
after each line is a semicolon
1:16:40
yeah semicolons not quote I'm singing Json for some odd reason So based on this
1:16:46
is that the correct correct syntax I mean I think it is
1:16:53
oh you have to do it after that too okay I missed that that's correct okay yeah
1:16:58
yeah all right
1:17:03
um let's go ahead and set the console font just in case we have to come back to TTY I don't have
1:17:09
to keep setting font all right let's uh reconfigure NYX OS
1:17:15
rebuild switch yeah oh console keymaps defined in more than
1:17:22
one spot of course it's the one thing I didn't even care about key map
1:17:28
is it defined in one more in response I don't see it Define anywhere else oh it's getting annoying well let's
1:17:34
define our hostname I guess let's use that let's clean this up a little bit I'm just sitting here no no
1:17:41
proxy select internationalism properties
1:17:47
okay console configure team
1:17:54
map in X11 I'm guessing the console can't be declared twice here oh right here so
1:18:02
it's it's doing the key map in X11 and then also on the console I think we can still leave the console config alone
1:18:08
cups I don't use printing here uh enable sound touchpad support not needed user
1:18:16
account I almost don't even want to install any user packages there but that's okay and
1:18:22
then we got the system packages so this is where you control services if
1:18:28
you got any extras that's fine we might come back with the firewall I'll leave that in all right hmm
1:18:36
let's make sure what is that lvm group
1:18:42
if we look at the lvm group for the home folder it is
1:18:47
oh no no no that's ext4 I got it wrong oh
1:18:53
if you look right up here you can see VG Dash
1:18:59
lv-1 is incorrect that should actually be ext4 instead of
1:19:06
better FS I thought that was just wanted to double check it because I was unsure so if we look at file system type
1:19:13
man this is so wonky so different kind of like different though
1:19:19
ext4 is what this is going to be and I do want to check one more time the
1:19:25
syntax of that file system's home NYX OS help
1:19:30
and then let's take a look at file systems again device equals blah blah blah FS okay
1:19:39
yeah I did I got it right so that's done now we just rebuild this time around
1:19:45
should be fast okay that's good let's just restart
1:19:51
oh yeah yeah that's a good point this is a mutable file system if I install it from that package manager it'll
1:19:57
completely break on every single install yeah I was just trying to get to
1:20:04
the desktop but you're absolutely right we need to fix that first and foremost
1:20:10
absolutely correct there so um let's modify our NYX OS what is that
1:20:19
config oop sudo Vim Etc NYX OS configuration yeah
1:20:27
so we got d w m and d menu I'm not really patching we're going to just
1:20:32
leave the menu alone I'll come back and rip that out though that's good point same with st I will remove that as well
1:20:40
but I first want to get clone
1:20:45
will it uninstall that's a good question if we do a rebuild and we remove a
1:20:51
package so let's go sudo NYX OS rebuild switch does it remove the old package
1:20:58
interesting I guess we'll find out so let's do a git
Cloning DWM Setup
1:21:03
clone github.com Chris Titus oh actually let's take a
1:21:12
look I think do I have a GitHub directory yeah get clone
1:21:17
what did I call this we're gonna just do a non-writable clone
1:21:24
right now and we're gonna call this dwm Titus I think is what it was dwm Titus
1:21:33
now sudo make install I'll make I need build utilities dang it
1:21:41
should have looked that up before I did this um what are the make utilities it's make
1:21:47
but hmm
1:21:53
all right I could just get build utilities I kind of say it's getting old and
1:22:00
stalling stuff for this thing uh
1:22:05
oh that's okay that's okay don't rebuild every time I need to install a package kind of sucks but
1:22:13
that's all right all right we're gonna go here gnu make okay Reddit
1:22:19
[Music] all right uh e-links google.com
Titus is dogwater at using elinks
1:22:27
oh gosh is there what do we have no
1:22:35
um Essential Software I think this should get us what we need okay what is the
1:22:41
main mapping I can't remember elinks is uh just to shift down instead of skipping to the next link what is it
1:22:49
jump to link l keyboarding manager k move cursor down is not bound well how
1:22:57
does that make sense [Music] yes
1:23:03
move cursor up up yes it's weird weird e-links has some weird
1:23:10
wait yeah okay all right there we go it's like I just need to go
1:23:16
got pages Where is the maybe we just do a search hmm
1:23:25
I think we'll be doing we do a search here um go into key bindings uh
1:23:34
um [Music] oh this sucks I'm just gonna say right now
1:23:43
oh yes uh
1:23:49
okay oh we had somebody mention you can install pacca you can install packages
1:23:57
with Nick's EMV yeah I think that's creates a specialized environment for it I'd like it for system-wide is kind of
1:24:03
what I'm thinking um search packages let's just go search packages
1:24:10
oh no what happened okay there we go oh
1:24:15
oh I gotcha search packages ah there's no up
1:24:21
um all right NYX OS search
1:24:26
mixed packages search okay negative what happened there
1:24:34
this is a subreddit isn't it oh Jesus all right I'm done with that
1:24:39
um okay I I want to build dwm but I can't I
1:24:45
guess I don't have the build tools and if I don't have the build tools how the hell am I gonna do it okay first
1:24:52
roadblock it's been a little bit we've it's been Cruise easy easy sailing so
1:24:58
far uh let's just do a q a
1:25:03
build let's see what kind of uh query NYX has for us for build
1:25:11
it has to has like a I'm like a group build Essentials package for compiling stuff
1:25:17
hmm all right what about Essentials or essential
1:25:22
sometimes that could be essential it's under STD environment really
1:25:29
oh well let's see we got uh error on our make why is that an airing out
1:25:38
error one two seven we're probably missing xcb I wonder if we can do Nick's
1:25:45
queries of xcb and see if that has
1:25:50
and probably it will also need xenorama okay
1:25:56
all right I probably will need what about Terminus fonts while we're
1:26:02
here I wonder if uh terminus so we don't have to rely on this sun
1:26:07
font uh okay Terminus Dash font is a thing so
1:26:16
wow what an interesting interesting way of doing things
1:26:22
all right somebody also said STD environment should give you the standard environment
1:26:29
we also wanted to grab my mind has gone blank oh Terminus font
1:26:35
Terminus font so now we do pseudo NYX OS rebuild switch
1:26:44
Terminus font is not there so the packages differ from Nick's environment
1:26:50
to the actual build system unless it's Terminus fonts
1:26:57
no that was not it um maybe ttf true type fonts
Wierd NixOS package names
1:27:05
let's try that if not Terminus is just not in there why does that why the hell does Nick's
1:27:11
environment packages differ from Nyx that's kind of disappointing
1:27:17
it's Terminus underscore font okay so there is no dash okay
1:27:23
so anything that requires a dash is probably an underscore now vert manager is in there [Music]
1:27:29
it's a little Jank it's a little janky because you allowed vert Dash manager but you didn't allow
1:27:35
Terminus and you changed that to underscore um not not the best
1:27:42
on the package naming but that's okay now we have our build
1:27:48
so now let's do a make still have some God tracking down dependencies to build
1:27:55
stuff is just gonna be a freaking nightmare oh my gosh
1:28:01
let me think about this this is a definite real world problem with Knicks because
1:28:08
like you're trying to track down like the xenorama or xcb dependencies of
1:28:16
dwm to build it well good good F and lock right like how
1:28:22
are you gonna track that down especially if you don't have a browser there's gotta be somebody that's already
1:28:28
set this up but NYX how it works and it being immutable you don't really install
1:28:34
packages on the system so it not having a very robust build
1:28:40
built you know ability to build and install packages in the system makes
1:28:45
sense because you typically would never install packages this way it's Bonkers but it does make sense
1:28:54
you can patch it see let's see here I do have a second system here one
1:28:59
second let me pull it up so I'm reading what was left in chat one second and
1:29:05
yeah somebody just linked it appreciate it NYX OS dot Wiki wikidwm
1:29:11
oh okay instead of doing a make oh wow
1:29:17
you put your patches in the overlays directory and then you're building on
1:29:24
the Nix rebuild it rebuilds dwm when you're doing the rebuild command
1:29:30
oh okay that definitely adds a level of complexity I really was not ready for
1:29:36
but it makes sense because that's just not how it's done in Nix
1:29:42
it's meant to be replicatable and if you're building stuff manually then it's not
1:29:48
ha wow so
1:29:53
yeah so you're using the Nyx Comfort literally everything
1:29:58
you will literally create a NYX packages overlay
1:30:03
let me let me start to do it I mean I'm super interested in this now because this has gotten
1:30:09
this is wild you just straight up Wild my mind is just
1:30:16
because we're literally building dwm on a Reload using
1:30:21
an overlay function basically in the next comp file I'm wrapping my brain
1:30:28
around it my brain's like that sounds amazing yeah as smart as AF
1:30:35
and you can do the same for St and D menu as well the cool part is you could even specify patches and from me reading
1:30:43
this Wiki here I got it on my other screen it looks like it will dynamically
1:30:49
grab the patches online as well instead of doing local diff files but if
1:30:55
you have coded your own specialized local div file it also has
1:31:00
another way to do that wow okay if you want to use fetch patch
1:31:06
you obtain the hash for the patch you want to apply that makes sense
MINDBLOWING NixOS Overlays
1:31:12
you tame the hash for the patch you need to run the command by Nick prefix URL
1:31:18
for example what the world that is
1:31:25
completely amazing yeah this is
1:31:32
okay let's let's do it let's do it all right let's put dwm back
1:31:38
in oh yeah it's already in here okay so we have it there and then
1:31:45
what we're going to do okay is there an overlay section already
1:31:51
let's check that there's not an overlay section so now we have NYX packages
1:31:59
overlays equals in the overlays apparently
1:32:04
affect this hmm
1:32:09
because this one's system packages user Titus packages with packages okay
1:32:17
okay you can also yeah you can also segment these out into separate
1:32:23
files and then reference them or overlaying dwm patches
1:32:29
oh how so how do you overlay a configuration patch I'm like like let's say I want to change
1:32:35
my hotkeys it's also kind of trying to figure that out so Nick's packages
1:32:43
overlays hmm let's go self I need to change my damn font to this
1:32:49
sun 12 by 22 is super annoying self super
1:32:56
and then okay so then you'd go dwm sorry about the
1:33:02
four point default Vim skip here it's kind of nuts dwm dot override
1:33:11
attributes old atrs rack and then you'd put whatever it
1:33:18
is in there close that you'd close that with uh
1:33:24
something like this then close this with something like that
1:33:31
okay I'm just looking at this and I'm that's the syntax it has on the guide
1:33:39
well this makes my Rocky install look like nothing looks like man
1:33:45
what in the world all right I figured it out
1:33:51
this is all fine and dandy but from
1:33:57
here to here [Music] um no good
1:34:03
and I really don't like how this is set so I I just have too much to change I'm
1:34:10
not gonna have it self build but and we can still do some really cool
1:34:17
stuff because I have so many patches and other stuff and customizations I want to do I don't
1:34:23
want to put it all in Nick's format in an overlay but you can specify in the overlay
1:34:29
section to say hey in dwm
1:34:34
like this we can build it using an override
1:34:42
of the stock package manager and then change where it's looking for
1:34:50
the source code to something like this
1:34:55
and that would be
1:35:01
something in the neighborhood yeah
1:35:06
of that that looks about right so now what it's doing instead of
1:35:14
overlaying because it will literally you there's there's a spec separate overlay you can do where you specify the
1:35:20
download directory and then you grab the hash for the download directly from sucklist.org it'll download the patch
1:35:28
and it'll just patch it for you I don't want to do that because I have so much other stuff going on custom
1:35:34
configurations and other things that I really just wanted to use my patches
1:35:39
that I've designed with um my custom hotkeys all for my source
1:35:46
files because I distribute that out to let's say more people and
1:35:51
I wanted to just use my git directory this is how you do that but if you only
1:35:56
had like let's say three or four packet patches you want to apply and you're not really changing from the stock config
1:36:03
this way would probably be not ideal for you you can probably want to get it directly from sockless or if you're
1:36:09
really close to the stock sockless you probably wouldn't want to build from source but the thing I don't understand
1:36:16
is is it gonna grab the dependencies yeah yeah how would it how would it
1:36:22
handle 10 patches automatically because I I'm I'm patching well I did about seven patches in my
1:36:29
repo that I built from Source I've been spending all weekend on dwm a lot uh
1:36:34
kind of hacking around on my laptop which I've set up and I was like dude this is amazing still not a hundred percent it's not ready for prime time
1:36:41
but very very close yeah I tried Flex the patch it's the lazy way to do it but I don't like how
1:36:47
bloated it makes the comp file the config file gets so huge that I don't
1:36:53
like the flexi patch flexipatch is a great way to do it for those that don't really want to dive in but I really only
1:36:59
wanted to use like six or seven patches and flexipatch has like 50 and I'm like
1:37:05
I'm out on all that I just I kind of want a more minimal setup so but yeah
1:37:11
flex-a-patch is a good way for that let's see what this does because I am
1:37:16
super curious let's go sudo Knicks OS
1:37:21
rebuild switch all right does it build my version of
1:37:27
dwm oh messed that up I did mean
1:37:34
atrs okay getting status no such file or
1:37:40
directory um oh I'm in the wrong directory yep
1:37:51
let's try it now oh why did I do GitHub with a capital H that's so stupid of me get out
1:37:59
shut the front door cheese and crackers did that work
1:38:05
no way let's see bro
1:38:10
no it worked wow
1:38:16
wow how crazy is that
1:38:22
it built my dwm obviously there's some other Shenanigans here but what
1:38:30
wow dang ah this is nuts yeah first try
1:38:39
yeah I mean there's still so much to learn but I man
1:38:46
is really good what about Brave does it launch Brave ah brave is crashing on me
1:38:53
and I can't launch Kitty let's just try St
1:38:59
um um [Music]
1:39:06
we'll just use St for now um what happens when we do Brave who
1:39:12
doesn't like about oh I'm like pregnant oh oh I know it's happening
1:39:18
okay that's fine Titus okay so what we need to do here
1:39:26
we're gonna go CH own recursive Titus users
1:39:33
and then we're gonna go to Titus what's happening is since I pulled in
1:39:38
that from a rocky Linux or a weird distribution some of my home directories not being able to be properly read so
1:39:46
we're gonna just take ownership of it using the new Titus and users group yeah that was pretty wild
1:39:54
that was so wild um jeez
1:40:00
oh man all right cool so then we exit let's go
1:40:07
to our home now let's see what Brave kicks up this time perfect so now if we're in a new thing
1:40:14
we launch Brave Brave no okay
1:40:19
so this fixes my rebuild errors with dwm I think as well
1:40:25
if I'm thinking correctly here we should be able to hmm
1:40:31
no no there's still some issues I'm thinking of anyways uh my launch of
1:40:38
Brave probably is just a different executable okay yeah that's it
1:40:44
then we got St so why doesn't if we go into Kitty okay
bin bash errors with it not existing
1:40:51
failed to launch child bin bash with air no such file or directory because it's
1:40:57
trying to launch Bash from here yeah so we fixed all our permissions in here
1:41:05
except for like win 11 stock image which let's just remove that
1:41:11
nah can't remove really operation not permitted Ah that's odd
1:41:17
I'm root what huh we'll have to revisit that I don't
1:41:23
know what's happening with it but uh let's see Ben okay there is no bin there's an sh
1:41:31
what about user Ben environment no
1:41:44
um [Music] okay
1:41:49
yeah that file looks odd I don't know what's happened with that that's interesting
1:41:54
it's so the weird part about this whole system so we've got it pretty much functional I've still got to fix some
1:42:01
little things here like referencing bin bash doesn't work I think the next question I have for
1:42:08
this is if we do a listing like where does it stick everything
1:42:16
like there's nothing in bin you have your standard boot with the EFI
1:42:22
stuff you have your devices which have all your devices
1:42:28
you have Etc which kind of just Sim links to stuff
1:42:35
like let's do a long listing of Etc where's it sync so it sinks into
1:42:42
everything's referenced from a NYX store that's so crazy to me
1:42:49
it's all on forward slash Knicks but how the hell you reference it like let's say I want to reference Bash
1:42:56
how do you do it these are good questions that I don't have answers to yet
1:43:05
um well there's static so it does stick some normal stuff in
1:43:13
static Etc static that doesn't change there's a shells directory what is this
1:43:22
shells bin oh shells is not a directory shells is
1:43:28
another simile going somewhere else where's that going oh it's going to another store wow I guess we can go
1:43:35
which Bash okay so it puts bash in run current system as
1:43:44
W bin Bash wow this is so crazy
1:43:49
let's see yeah yeah that's got to be a Sim link too let's go run current system
1:43:55
SW been oh that's definitely a Sim link but it
1:44:02
puts it all there these Sim links are going to change see because this is referencing a specific
1:44:08
version from an update so these versions will not hang around we're gonna have to
1:44:16
this is the perfect spot to reference them though so if we do which bash and it's referencing
1:44:23
it from here and let's say we launch another St terminal and
1:44:30
uh what is that oh no no Ctrl shift there it is all right it's like I can't
1:44:37
remember so you reference that from our Bash
1:44:43
RC uh Neo vims not installed oh
1:44:51
Shucks okay what happens when we rebuild this stuff on the Fly
1:44:56
we need to add more stuff neovim I don't know how I forgot any of them that's
1:45:01
just odd of me but Etc man
1:45:09
Starship Starship okay neofim still using a 0.81 fork but
1:45:17
that's okay neovim starfit what about Auto jump Auto jumps there too okay Auto jump
1:45:24
neovim and pseudo Vim
1:45:29
Etc nixos configuration
1:45:34
so neovim Auto jump
1:45:40
Starship and then we go sudo NYX OS
1:45:45
rebuild switch okay them
1:45:51
Basher see huh okay Bash
1:45:57
is that where it's referencing it from is every script has to be changed from forward slash bin Bash
1:46:03
I feel like that's a little excessive but I feel like that's why we're having problems on the launch
1:46:09
I wonder if we can just hack it and just kind of I did see a link to sh there
1:46:16
what does that even look like let's just go Kitty now no bin bash hmm
1:46:25
that's not it hmm yeah let's cat Etc shells so if we
1:46:31
look over here cat Etc shelves
1:46:37
it's got to be that intro line right or it could be something in the kitty.com as well
1:46:43
but hmm yeah your kitty cat comp file I think it's something like that I think
1:46:48
it's some of the kitty cops so let's just go config Kitty kitty.com
1:46:55
is there bash yeah there it is that's the culprit
1:47:01
so then it would be a run Dash current system SW
1:47:07
bin Bash so then we close that out come to a new workspace Kitty
1:47:14
ah all right close that come back to here
1:47:20
let's fix this even further so the auto jump is wrong
1:47:27
we go which Auto jump you can see auto jump being in that same issue so to fix
1:47:35
that Auto jump so Auto jump dot sh autojump.sh hmm
1:47:46
can't found the auto jump script
1:47:51
um and if we go which Auto jump so how's it
1:47:57
referencing Auto jump that's not anything with DOT pity
1:48:03
kitty.com Auto jump yeah it's not in here
1:48:08
be pretty much fixed this file
1:48:15
but I also notice our starship's a little janky maybe St is the way forward
1:48:21
true I think it would automatically pick the environment there's so many good
1:48:27
questions here guys so many good questions so no yes
1:48:33
yeah wow well we've successfully moved to Nyx
Successful Install and Recap .
1:48:41
this is so interesting
1:48:47
so interesting the kernel is actually kind of old too look at the Nyx OS kernel we're rocking 5.15.
1:48:54
but yeah de's none dwm and dwm a lot of people are probably not liking
1:49:01
my aesthetic choice of tossing my stuff up here but I kind of like this setup I know it looks ugly
1:49:07
but it's so functional just so functional yeah yeah this is totally
1:49:13
where all the cool kids hang out Citrus welcome yeah I love the Simplicity of dwm it's
1:49:21
doesn't have a lot of flair but man you can just do anything you want I
1:49:27
obviously dwm usually just has numbers instead of doing like icons and other
1:49:32
stuff I can just pull up any new workspace or let's say I kill that one I
1:49:38
can just pull up any workspace and then just I I just wanted to modify it a little bit and I was like dude you can do
1:49:43
anything and it just I made it to where it closes all the other tags and then just lists what things I have to open
1:49:50
because I usually don't have more than you know four or five things open and I'd rather it just list it at the top
1:49:56
yeah and I I love the flexibility the speed the fact that it just can't break
1:50:02
like you get it built once and you like that config nothing will ever break it
1:50:08
it's so freaking simple that it's like bulletproof I love that
1:50:15
yeah I should probably bling it out a little more because I think it would be a lot more appealing for more people but
1:50:21
as I I was more just working on the function of it I was like dwm and the function it's just so good
1:50:27
yeah I would say definitely do Knicks in a VM if you're gonna do this this was a
1:50:35
huge step like if I had to go back knowing what I know now
1:50:41
I probably would not have done this on my studio PC that I'm on all the time because
1:50:46
holy crap that was way different than any other Linux install I've ever done
1:50:51
in my entire life that's saying something I've installed a lot of different Linux distros but this
1:50:58
one was just Wild I mean but in a great way like
1:51:06
it it's like someone just took it takes a special mind not to just copy other
1:51:12
people's work and that's what the Nyx OS really did here is they didn't they took
1:51:17
what everybody else has done on os's and they're just like just I'm gonna do my own thing and then
1:51:23
that's what they did here and that's super cool I really am
1:51:28
appreciative and I love how I could easily just give you guys my configuration.nix and you would just
1:51:35
have everything you see here that's kind of nuts with a couple exceptions because you would have to
1:51:42
clone my dwm because I put in my NYX comp file that look in home Titus GitHub
1:51:51
dwm and then you see all those source files go ahead and build that so anytime
1:51:56
I run it's rebuilding my dwm based on my my setup
1:52:02
that's nuts that just that was a complete mind-blowing moment
1:52:07
welcome to the world of dwm users I've only been trying to convince you for four years thank you Peter for not
1:52:14
giving up on me what about X monad probably we can check
1:52:19
into that uh x monads stock configuration is made
1:52:24
by a Madman though I looked at the key bindings in ex monad and I'm like whoa
1:52:31
this person was on drugs when they made these key bindings but it's kind of funny I like those obscure ones too like
1:52:38
I said thinking outside of the box and sometimes those people's minds work way different
1:52:43
than the rest of us and then it's just trying to wrap around a new way of thinking that
1:52:49
so neat just so neat yeah well I'm about to make a new video that I've been
1:52:55
trying to design and I I wanted to you guys can give me your feedback on this chat
1:53:00
Windows to Linux for power users and it's gonna be installing Linux three times
1:53:08
three different ways none of which is using a GUI it'll be the first one using like a more
1:53:15
simplistic minimal build using task SEL from like a Debian install right pretty
1:53:21
basic you can just grab your desktop environment everyone should be able to follow around like that's like level one
1:53:27
right so that that takes out the GUI and that's going to be people going oh that's interesting and then level two
1:53:34
will go to a minimal Arch build where we're building Arch basically using Arch
1:53:41
Wiki you know I think that's a great way to kind of learn the components of Linux and I think everyone should do this
1:53:48
if you if you want to be a power user you know and really understand Linux and then once you get through that entire
1:53:54
Arch build where you're building like the bootloader and doing grub or system D and then installing your packages one
1:54:01
by one and loading it out then we go to like level three and level three is like
1:54:08
a very unique build maybe even we do Knicks for level three because I love
1:54:13
the design of it but uh yeah I'm just I'm thinking something
1:54:19
in that neighborhood where you're building out and learning all the different components of Linux because once you
1:54:25
learn those components like it doesn't matter where you go like it does like even NYX even though it gave us some
1:54:30
problems we still understood hey where's the USR folders where where's
1:54:35
the bin folder where where are these things because Linux still needs to reference those and the program still
1:54:41
need to reference them it's just like but how Nicks do it and that's kind of like
1:54:46
uh the thought process because I always understood hey these components have to exist and then you you look at them that
1:54:53
way so but yeah that's my thought on the new windows to Linux it's gonna freak people
1:54:59
out I'm gonna get a ton of hate comments but there's gonna be a couple power users out there that will freaking love it because I would have loved to have a
1:55:06
a video like that when I first started doing Linux level 4 gen 2.
1:55:14
uh level five lfs yeah that video would be like five hours long it'd be great I would love it
1:55:21
oh man well this was amazing I love the little NYX dwm it was so great and I I
1:55:29
will see how long I last on it but I I really love the newness it's like
1:55:36
getting in a new car for the first time and you're like nothing's like my old car and that's the beauty of this setup
1:55:43
right here and we'll see how long it lasts you know me I get bored and I'm like okay I'm going on the next thing
1:55:48
but there's a lot to learn with NYX and there's a huge amount to absorb here uh
1:55:56
so I don't know I bet you I bet you I stay on it longer than a month and that's High Praise coming from me
1:56:02
foreign oh man it was so much fun so much fun so
1:56:08
thank you guys for for hanging in there with me seeing me read and try to understand NYX and
1:56:15
even even give me hints here and there ah but it's so great and you thank you
1:56:20
big shout out to Peter do thank you for for the dwm I still have been I've been
1:56:26
I've wasted the last two or three days just at night on my laptop customizing
1:56:32
my dwm and this is kind of what I've got from the stock one you notice I might have gone to 6.3 from 6.4 for patches
1:56:40
some of the patches I was using I was like ah I'm tired of changing this and I wanted it to be a little more Universal
1:56:46
with some older distros and I think 6.4 was giving me a couple headaches maybe not though I probably need to rebuild
1:56:53
from from Source again but I'm sold on dwm I love it it's so so
1:56:59
cool and I love uh nyx's intro but with that y'all I'm gonna sign off
1:57:06
thank you all have a great time I'll be back on Thursday we'll see what we do
1:57:11
for Thursday stream I probably need to revisit Windows tools and all those as it been a little bit since I've worked
1:57:17
on them but I might still be still messing around with Nick so I don't know
1:57:23
we'll see how I'm feeling on Thursday uh be looking at the stream title I'll try and set all that up so
1:57:30
thank you guys see y'all in the next one
