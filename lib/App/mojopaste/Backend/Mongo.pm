package App::mojopaste::Backend::Mongo;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::File 'path';
use Mojo::Util qw(encode decode);
use Text::CSV;

my $ID = 0;

sub register {
  my ($self, $app, $config) = @_;
  my $dir = $app->config('paste_dir');
  path($dir)->make_path unless -d $dir;

  $app->plugin( 'Mango', {
    mango      => 'mongodb://mongo:27017/paste',
    helper     => 'db',
    default_db => 'mojopaste',
  });

  $app->helper('paste.load_p' => sub { _load_p($dir, @_) });
  $app->helper('paste.save_p' => sub { _save_p($dir, @_) });
}

sub _load_p {
  my ($dir, $c, $id) = @_;
  my @res = ('', '');

  eval {
    die "Hacking attempt! paste_id=($id)" if !$id or $id =~ m!\W!;

    my $promise = Mojo::Promise->new;
    $c->collection('docs')->find_one({id => $id}, { _id => 0 } => sub {
      my ($collection, $err, $doc) = @_;
      $promise->resolve( $doc->{body} );
      $promise->reject( $err );
    });

    return $promise;
  } or do {
    return Mojo::Promise->new->reject($@ || 'Paste not found');
  };
}

sub _save_p {
  my ($dir, $c, $text) = @_;
  my $id = substr Mojo::Util::md5_sum($$ . time . $ID++), 0, 12;
  my @res = ('', '');

  eval {
    die "Hacking attempt! paste_id=($id)" if !$id or $id =~ m!\W!;

    my $promise = Mojo::Promise->new;
    my $doc = { id => $id, body => $text };
    $c->collection('docs')->insert($doc => sub {
      my ($collection, $err, $oid) = @_;
      $promise->resolve( $id );
      $promise->reject( $err );
    });

    return $promise;
  } or do {
    return Mojo::Promise->new->reject($@ || 'Unknown error');
  };
}

1;
