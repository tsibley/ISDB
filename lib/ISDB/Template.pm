use 5.010;
use strict;
use warnings;
use utf8;

package ISDB::Template;
use Template::Alloy;
use ISDB::Config;
use ISDB::Schema;
use Hash::Merge qw< merge >;
use DateTime::Format::RFC3339;
use URI::Escape qw< uri_escape_utf8 >;
use namespace::clean;

sub fill {
    my $self     = shift;
    my $source   = shift;
    my $args     = shift || {};
    my $isdb     = ISDB::Schema->connect_default;
    my $defaults = {
        isdb   => $isdb,
        config => ISDB::Config->new->conf,

        parse_timestamp => sub {
            my $timestamp = shift // return undef;
            state $rfc3339 = DateTime::Format::RFC3339->new;
            my $dt = $rfc3339->parse_datetime($timestamp);
            $dt->set_time_zone('US/Pacific');
            return $dt;
        },

        version_url => sub {
            my $v = shift;
            return ($v and $v->{frozen})
                ? "frozen/" . uri_escape_utf8($v->{name}) . "/"
                : "";
        },
    };
    $args = merge($args, $defaults);

    state $template = Template::Alloy->new(
        START_TAG       => '<%',
        END_TAG         => '%>',
        AUTO_FILTER     => 'html',
        ENCODING        => 'UTF-8',
        ABSOLUTE        => 1,
        RELATIVE        => 1,
        ADD_LOCAL_PATH  => 1,
        FILTERS         => {
            commafy     => sub {
                my $num = shift // return undef;
                   $num = reverse $num;
                   $num =~ s/(?<=\G\d{3})(?!$)/,/g;
                   $num = reverse $num;
                return $num;
            },
        },
    );
    my $filled = "";
    $template->process($source, $args, \$filled)
        or die $template->error, "\n";
    return $filled;
}

1;
