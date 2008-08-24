use Test::More tests => 10;
use Test::Warn;
use Test::Exception;

BEGIN { use_ok('Net::Identica') };

my $identi;
dies_ok  { $identi = Net::Identica->new('alanhaggai', 'topsecret') } 'Correct username and wrong password';
lives_ok { $identi = Net::Identica->new('alanhaggai'             ) } 'Correct username';
isa_ok($identi, 'Net::Identica',                                     'Object created successfully');
my @messages = $identi->get;
ok(@messages >= 1,                                                   'It is indeed an array');

dies_ok { $identi = Net::Identica->new(''                                           ) } 'Invalid username';
dies_ok { $identi = Net::Identica->new(''                                 , 0       ) } 'Invalid username and invalid password';
dies_ok { $identi = Net::Identica->new(''                                 , 'qwerty') } 'Invalid username and valid password';
dies_ok { $identi = Net::Identica->new('alanhaggai'                       , ''      ) } 'Correct username and invalid password';
dies_ok { $identi = Net::Identica->new('ihopethereisnoonewiththisusername', 'public') } 'Wrong username and wrong password';
