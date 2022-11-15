![Dialyzer](https://github.com/cutecutecat/emqttsn/actions/workflows/dialyzer.yml/badge.svg)  ![test](https://github.com/cutecutecat/emqttsn/actions/workflows/test.yml/badge.svg) ![page](https://github.com/cutecutecat/emqttsn/actions/workflows/page.yml/badge.svg)

# emqtt-sn

🌐 emqtt-sn is a light-weight `MQTT-SN` client. It is both client library and command line tools implemented in Erlang that supports `MQTT-SN` v1.2.

🚗 Enjoy your tour of `MQTT-SN` communication!

**What emqtt-sn support**

* ⏳ Automatic response and timeout control
* ⭐⭐ **all** operations are supported used as a lib
* ⭐ `subscribe` and `publish` when used as a client
* 🛏️ sleeping feature

* ➡️ QoS -1, 0, 1, 2 support

**What emqtt-sn cannot do**

* ❌ Forwarder Encapsulation (no plan to support)
* ❌ Zigbee support (no plan to support)

* ❌ Define Radius of `SEARCHGW` and `GWINFO` (see current difficulties)
* ❌ Received `GWINFO` with arbitrary port (see current difficulties)

[document](https://cutecutecat.github.io/emqttsn/edoc) | [coverage report](https://cutecutecat.github.io/emqttsn/cover)

## How to use

### As a Dynamic Library

When use as a lib, you can introduce into the `rebar.config` of your `erlang` project:

```erlang
{emqttsn, {git, "https://github.com/emqx/emqttsn", {branch, "main"}}
```

### As a Command Line Tool

When use as a client, run `make` in project root directory.

Once you've compiled successfully you will get a script called `emqttsn` in `_build/emqttsn/rel/emqttsn/bin`. We can see what `emqtt` can do with `--help` option:

```
$ ./emqttsn --help
Usage: emqttsn pub | sub [--help]
```

`emqttsn pub` is used to publish a single message on a topic and exit. `emqttsn sub` is used to subscribe to a topic and print the messages that it receives.

**publish**

```
Usage: emqttsn pub [-n [<name>]] [-h [<host>]] [-p [<port>]] [-I <iface>]
                   [-w [<will>]] [-V [<protocol_version>]]
                   [-k [<keepalive>]] [-t [<topic_id_type>]]
                   [-i <topic_id>] [-m <topic_name>] [-q [<qos>]]
                   [-r [<retain>]] [--help <help>]
                   [--will-topic <will_topic>]
                   [--will-message <will_msg>] [--will-qos [<will_qos>]]
                   [--will-retain [<will_retain>]] [--message <message>]

  -n, --name              client name(equal to client_id, unique for each 
                          client) [default: client]
  -h, --host              mqtt-sn server hostname or IP address [default: 
                          127.0.0.1]
  -p, --port              mqtt-sn server port number [default: 1884]
  -I, --iface             specify the network interface or ip address to 
                          use
  -w, --will              whether the client need a will message [default: 
                          false]
  -V, --protocol-version  mqtt-sn protocol version: v1.2 [default: 2]
  -k, --keepalive         keep alive in seconds [default: 300]
  -t, --topic_id_type     mqtt topic id type(0 - topic id, 1 - predefined 
                          topic id, 2 - short topic name) [default: 1]
  -i, --topic_id          mqtt topic id on which to publish the 
                          message(exclusive with topic_name)
  -m, --topic_name        mqtt topic name on which to publish the 
                          message(exclusive with topic_id)
  -q, --qos               qos level of assurance for delivery of an 
                          application message [default: 0]
  -r, --retain            retain message or not [default: false]
  --help                  Help information
  --will-topic            Topic for will message
  --will-message          Payload in will message
  --will-qos              QoS for will message [default: 0]
  --will-retain           Retain in will message [default: false]
  --message               application message that is being published
```

**subscribe**

```
Usage: emqttsn sub [-n [<name>]] [-h [<host>]] [-p [<port>]] [-I <iface>]
                   [-w [<will>]] [-V [<protocol_version>]]
                   [-k [<keepalive>]] [-t [<topic_id_type>]]
                   [-i <topic_id>] [-m <topic_name>] [-q [<qos>]]
                   [--help <help>] [--will-topic <will_topic>]
                   [--will-message <will_msg>] [--will-qos [<will_qos>]]
                   [--will-retain [<will_retain>]]

  -n, --name              client name(equal to client_id, unique for each 
                          client) [default: client]
  -h, --host              mqtt-sn server hostname or IP address [default: 
                          127.0.0.1]
  -p, --port              mqtt-sn server port number [default: 1884]
  -I, --iface             specify the network interface or ip address to 
                          use
  -w, --will              whether the client need a will message [default: 
                          false]
  -V, --protocol-version  mqtt-sn protocol version: v1.2 [default: 2]
  -k, --keepalive         keep alive in seconds [default: 300]
  -t, --topic_id_type     mqtt topic id type(0 - topic id, 1 - predefined 
                          topic id, 2 - short topic name) [default: 1]
  -i, --topic_id          mqtt topic id on which to subscribe to(exclusive 
                          with topic_name)
  -m, --topic_name        mqtt topic name on which to subscribe 
                          to(exclusive with topic_id)
  -q, --qos               maximum qos level at which the server can 
                          receive application messages to the client 
                          [default: 0]
  --help                  Help information
  --will-topic            Topic for will message
  --will-message          Payload in will message
  --will-qos              QoS for will message [default: 0]
  --will-retain           Retain in will message [default: false]
```



## Supported Operations

### official operation

This client deployment follows version `MQTT-SN` protocol v1.2 as [here](doc/MQTT-SN_spec_v1.2.pdf).

Official operation is main API of  `MQTT-SN` communication.

| Ops         | use as lib | use as client |
| ----------- | ---------- | ------------- |
| publish     | ✅          | ✅             |
| subscribe   | ✅          | ✅             |
| unsubscribe | ✅          | ❌             |
| register    | ✅          | ❌             |
| sleep       | ✅          | ❌             |
| connect     | ✅          | ❌             |
| disconnect  | ✅          | ❌             |

### unofficial operation

unofficial operations are not mentioned in `MQTT-SN` protocol document, but useful for development and communication. They are only available when use as a lib.

| Ops                   | description                                            |
| --------------------- | ------------------------------------------------------ |
| start_link            | start a emqttsn client                                 |
| add_host              | Manually add a gateway host                            |
| get_state             | Get state data of the client                           |
| get_state_name        | Get state name of the client                           |
| reset_config          | Set new config of the client                           |
| stop                  | Only Stop the state machine client, but not disconnect |
| finalize              | Stop and disconnect the client                         |
| wait_until_state_name | Block until client reach target state                  |

## examples

While using this client, you need to deploy a `MQTT-SN` protocol gateway first. 

We recommend to use [EMQX](https://github.com/emqx/emqx) as it has been tested for compatibility.

When use as a lib, we can build a simple `MQTT-SN` client like this:

```erlang
-define(HOST, {127, 0, 0, 1}).
-define(PORT, 1884).

% Id of MQTT-SN gateway
GateWayId = 1,
Retain = false,
TopicIdType = ?SHORT_TOPIC_NAME,
TopicName = "tn",
Message = "Message",
Qos = ?QOS_0,
Block = true,

% start a MQTT-SN client
{ok, Client, _} = emqttsn:start_link("client", []),

% add gateway host manually(you can also let it from ADVERTISE or GWINFO)
emqttsn:add_host(Client, ?HOST, ?PORT, GateWayId),

% connect of target gateway
emqttsn:connect(Client, GateWayId, Block),

% register a topic name
emqttsn:register(Client, TopicName, Block),
    
% subscribe to some topic name
emqttsn:subscribe(Client, TopicIdType, TopicName, Qos, Block),

% publish a message to some topic name
emqttsn:publish(Client, Retain, TopicIdType, TopicName, Message, Block),
```

more examples can be found [here](test/emqttsn_protocol_SUITE.erl).

## current difficulties

**About Radius**

There is no `radius` in Local Area Network (LAN), which means broadcast radius  . There is a similar concept as Time To Live (TTL), but a broadcast packet will nearly always be dropped by route as it is the default setting. It seems in vain to make `radius` to `TTL`.

In `emqttsn`, user can set radius, but they will have no effect at all. The radius of received packet will be extracted correctly parsed, but they will also not be used anywhere.

**About GWInfo port**

For GWInfo packet from other client, it will be like:

| Length    | MsgType | GwId | GwAdd |
| --------- | ------- | ---- | ----- |
| (octet 0) | (1)     | (2)  | (3:n) |

For consistency of definition, we only make `GwAdd` for gateway host (Address, like 127.0.0.1), but without port. 

If a client receive such packet, **it will set default port (1884) for gateway!** 

Be cautious to pick any non-standard port for gateway!

