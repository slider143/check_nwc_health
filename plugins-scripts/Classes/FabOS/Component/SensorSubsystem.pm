package Classes::FabOS::Component::SensorSubsystem;
@ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('SW-MIB', [
      ['sensors', 'swSensorTable', 'Classes::FabOS::Component::SensorSubsystem::Sensor'],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking sensors');
  $self->blacklist('ses', '');
  foreach (@{$self->{sensors}}) {
    $_->check();
  }
}


package Classes::FabOS::Component::SensorSubsystem::Sensor;
our @ISA = qw(GLPlugin::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub check {
  my $self = shift;
  $self->blacklist('se', $self->{swSensorIndex});
  $self->add_info(sprintf '%s sensor %s (%s) is %s',
      $self->{swSensorType},
      $self->{swSensorIndex},
      $self->{swSensorInfo},
      $self->{swSensorStatus});
  if ($self->{swSensorStatus} eq "faulty") {
    $self->add_critical($self->{info});
  } elsif ($self->{swSensorStatus} eq "absent") {
  } elsif ($self->{swSensorStatus} eq "unknown") {
    $self->add_critical($self->{info});
  } else {
    if ($self->{swSensorStatus} eq "nominal") {
      #$self->add_ok($self->{info});
    } else {
      $self->add_critical($self->{info});
    }
    $self->add_perfdata(
        label => sprintf('sensor_%s_%s', 
            $self->{swSensorType}, $self->{swSensorIndex}),
        value => $self->{swSensorValue},
    ) if $self->{swSensorType} ne "power-supply";
  }
}


package Classes::FabOS::Component::SensorSubsystem::SensorThreshold;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach my $param (qw(entSensorThresholdRelation entSensorThresholdValue
      entSensorThresholdSeverity entSensorThresholdNotificationEnable
      entSensorThresholdEvaluation indices)) {
    $self->{$param} = $params{$param};
  }
  $self->{entPhysicalIndex} = $params{indices}[0];
  $self->{entSensorThresholdIndex} = $params{indices}[1];
  bless $self, $class;
  return $self;
}
