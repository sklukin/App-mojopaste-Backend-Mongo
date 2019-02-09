package App::mojopaste::Backend::Mongo;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Promise;

my $ID = 0;

sub register {
  my ($self, $app, $config) = @_;

  my $mongo_uri = $ENV{MONGO_URI} || 'mongodb://mongo:27017/paste';
  $app->plugin( 'Mango', {
    mango      => $mongo_uri,
    helper     => 'db',
    default_db => 'mojopaste',
  });

  $app->helper('paste.load_p' => sub { _load_p(@_) });
  $app->helper('paste.save_p' => sub { _save_p(@_) });
}

sub _load_p {
  my ($c, $id) = @_;

  eval {

    my $promise = Mojo::Promise->new;
    $c->collection('docs')->find_one({id => $id}, { _id => 0 } => sub {
      my ($collection, $err, $doc) = @_;

      return $err ? $promise->reject($err) : $promise->resolve($doc->{body});
    });

    return $promise;
  } or do {
    return Mojo::Promise->new->reject($@ || 'Paste not found');
  };
}

sub _save_p {
  my ($c, $text) = @_;
  my $id = substr Mojo::Util::md5_sum($$ . time . $ID++), 0, 12;

  eval {
    my $promise = Mojo::Promise->new;
    $c->collection('docs')->insert({ id => $id, body => $text } => sub {
      my ($collection, $err, $oid) = @_;

      return $err ? $promise->reject( $err ) : $promise->resolve( $id );
    });

    return $promise;
  } or do {
    return Mojo::Promise->new->reject($@ || 'Unknown error');
  };
}

1;
