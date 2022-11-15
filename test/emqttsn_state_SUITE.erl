%%--------------------------------------------------------------------
%% Copyright (c) 2022 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqttsn_state_SUITE).

-compile(export_all).
-compile(nowarn_export_all).

-include("emqttsn.hrl").

-include_lib("eunit/include/eunit.hrl").

-define(HOST, {127, 0, 0, 1}).
-define(PORT, 1884).

init_per_testcase(_TestCase, _Cfg) ->
    meck:unload().

end_per_testcase(_TestCase, _Cfg) ->
    meck:unload().

%%--------------------------------------------------------------------
%% setups
%%--------------------------------------------------------------------

all() ->
    [t_initialize_timeout,
     t_receive_advertise,
     t_receive_gwinfo_from_client,
     t_receive_gwinfo_from_gateway,
     t_connect_timeout,
     t_connack_rc_failed,
     t_register_rc_failed,
     t_register_timeout,
     t_subscribe_rc_failed,
     t_subscribe_timeout,
     t_unsubscribe_timeout,
     t_recv_pingreq,
     t_send_pingreq,
     t_pub_qos1_rc_failed,
     t_pub_qos1_timeout,
     t_pub_qos2_pub_timeout,
     t_pub_qos2_pubrel_timeout,
     t_pub_qos2_pubrec_timeout].

t_initialize_timeout(_Cfg) ->
    {ok, _} = emqttsn_state:start_link("SendGw", #config{search_gw_interval = 50}),
    timer:sleep(200).

t_receive_advertise(_Cfg) ->
    {ok, Client, _} = emqttsn:start_link("RecvAdv"),
    #state{socket = Socket} = emqttsn:get_state(Client),

    GateWayId = 16#01,
    Duration = 50,
    Packet = ?ADVERTISE_PACKET(GateWayId, Duration),
    Bin = emqttsn_frame:serialize(Packet, #config{}),
    spawn(emqttsn_udp_SUITE, sender, [Client, {udp, Socket, ?HOST, ?PORT, Bin}]),
    ?assertNotEqual(#gw_info{id = GateWayId,
                             host = ?HOST,
                             from = ?BROADCAST},
                    emqttsn_utils:get_gw("RecvAdv", GateWayId, true)),
    emqttsn:finalize(Client).

t_receive_gwinfo_from_client(_Cfg) ->
    {ok, Client, _} = emqttsn:start_link("RecvGWInfoCli"),
    #state{socket = Socket} = emqttsn:get_state(Client),

    GateWayId = 16#01,
    GateWayAdd = {127, 1, 1, 1},
    Packet = ?GWINFO_PACKET(GateWayId, GateWayAdd),
    Bin = emqttsn_frame:serialize(Packet, #config{}),
    spawn(emqttsn_udp_SUITE, sender, [Client, {udp, Socket, ?HOST, ?PORT, Bin}]),
    ?assertNotEqual(#gw_info{id = GateWayId,
                             host = GateWayAdd,
                             from = ?PARAPHRASE},
                    emqttsn_utils:get_gw("RecvGWInfoCli", GateWayId, true)),
    emqttsn:finalize(Client).

t_receive_gwinfo_from_gateway(_Cfg) ->
    {ok, Client, _} = emqttsn:start_link("RecvGWInfoGat"),
    #state{socket = Socket} = emqttsn:get_state(Client),

    GateWayId = 16#01,
    Packet = ?GWINFO_PACKET(GateWayId),
    Bin = emqttsn_frame:serialize(Packet, #config{}),
    spawn(emqttsn_udp_SUITE, sender, [Client, {udp, Socket, ?HOST, ?PORT, Bin}]),
    ?assertNotEqual(#gw_info{id = GateWayId,
                             host = ?HOST,
                             from = ?BROADCAST},
                    emqttsn_utils:get_gw("RecvGWInfoGat", GateWayId, true)),
    emqttsn:finalize(Client).

t_connect_timeout(_Cfg) ->
    % set a short timeout interval to let it resend
    {ok, Client, _} = emqttsn:start_link("ConnTimeout", [{ack_timeout, 10}, {max_resend, 5}]),

    GateWayId = 16#01,
    emqttsn:add_host(Client, ?HOST, ?PORT, GateWayId),
    emqttsn:connect(Client, GateWayId, false),

    % wait until timeout
    timer:sleep(200),
    emqttsn:finalize(Client).

t_connack_rc_failed(_Cfg) ->
    {ok, Client, _} = emqttsn:start_link("ConnRcFailed"),
    #state{socket = Socket} = emqttsn:get_state(Client),

    GateWayId = 16#01,
    emqttsn:add_host(Client, ?HOST, ?PORT, GateWayId),

    emqttsn:connect(Client, GateWayId, false),

    % gateway return a UNSUPPORTED return code
    timer:sleep(200),
    Packet = ?CONNACK_PACKET(?RC_UNSUPPORTED),
    Bin = emqttsn_frame:serialize(Packet, #config{}),
    spawn(emqttsn_udp_SUITE, sender, [Client, {udp, Socket, ?HOST, ?PORT, Bin}]),

    timer:sleep(200),
    emqttsn:finalize(Client).

t_register_rc_failed(_Cfg) ->
    % make state machine start from fake connected
    ok = meck:new(emqttsn_state, [passthrough, no_history, no_link]),
    meck:expect(emqttsn_state,
                init,
                fun({Name, Port, Config}) ->
                   {ok, Socket} = emqttsn_udp:init_port(Port),
                   emqttsn_udp:connect(Socket, ?HOST, ?PORT),
                   {ok,
                    connected,
                    #state{name = Name,
                           socket = Socket,
                           config = Config}}
                end),

    {ok, Client, _} = emqttsn:start_link("RegRcFailed"),
    #state{socket = Socket} = emqttsn:get_state(Client),
    TopicName = "topic name",
    emqttsn:register(Client, TopicName, false),

    % gateway return a UNSUPPORTED return code
    timer:sleep(200),
    TopicId = 16#01,
    PacketId = 0,

    Packet = ?REGACK_PACKET(TopicId, PacketId, ?RC_UNSUPPORTED),
    Bin = emqttsn_frame:serialize(Packet, #config{}),
    spawn(emqttsn_udp_SUITE, sender, [Client, {udp, Socket, ?HOST, ?PORT, Bin}]),

    timer:sleep(200),
    emqttsn:finalize(Client).

t_register_timeout(_Cfg) ->
    % make state machine start from fake connected
    ok = meck:new(emqttsn_state, [passthrough, no_history, no_link]),
    meck:expect(emqttsn_state,
                init,
                fun({Name, Port, Config}) ->
                   {ok, Socket} = emqttsn_udp:init_port(Port),
                   emqttsn_udp:connect(Socket, ?HOST, ?PORT),
                   {ok,
                    connected,
                    #state{name = Name,
                           socket = Socket,
                           config = Config}}
                end),

    % set a short timeout interval to let it resend
    {ok, Client, _} = emqttsn:start_link("RegTimeout", [{ack_timeout, 10}, {max_resend, 5}]),
    TopicName = "topic name",
    emqttsn:register(Client, TopicName, false),

    % wait until timeout
    timer:sleep(200),
    emqttsn:finalize(Client).

t_subscribe_rc_failed(_Cfg) ->
    % make state machine start from fake connected
    ok = meck:new(emqttsn_state, [passthrough, no_history, no_link]),
    meck:expect(emqttsn_state,
                init,
                fun({Name, Port, Config}) ->
                   {ok, Socket} = emqttsn_udp:init_port(Port),
                   emqttsn_udp:connect(Socket, ?HOST, ?PORT),
                   {ok,
                    connected,
                    #state{name = Name,
                           socket = Socket,
                           config = Config}}
                end),

    {ok, Client, _} = emqttsn:start_link("SubRcFailed"),
    #state{socket = Socket} = emqttsn:get_state(Client),
    TopicIdType = ?SHORT_TOPIC_NAME,
    TopicIdOrName = "tn",
    MaxQos = ?QOS_0,
    emqttsn:subscribe(Client, TopicIdType, TopicIdOrName, MaxQos, false),

    % gateway return a UNSUPPORTED return code
    timer:sleep(200),
    Qos = ?QOS_0,
    TopicId = 16#01,
    PacketId = 0,

    Packet = ?SUBACK_PACKET(Qos, TopicId, PacketId, ?RC_UNSUPPORTED),
    Bin = emqttsn_frame:serialize(Packet, #config{}),
    spawn(emqttsn_udp_SUITE, sender, [Client, {udp, Socket, ?HOST, ?PORT, Bin}]),

    timer:sleep(200),
    emqttsn:finalize(Client).

t_subscribe_timeout(_Cfg) ->
    % make state machine start from fake connected
    ok = meck:new(emqttsn_state, [passthrough, no_history, no_link]),
    meck:expect(emqttsn_state,
                init,
                fun({Name, Port, Config}) ->
                   {ok, Socket} = emqttsn_udp:init_port(Port),
                   emqttsn_udp:connect(Socket, ?HOST, ?PORT),
                   {ok,
                    connected,
                    #state{name = Name,
                           socket = Socket,
                           config = Config}}
                end),

    % set a short timeout interval to let it resend
    {ok, Client, _} = emqttsn:start_link("SubTimeout", [{ack_timeout, 10}, {max_resend, 5}]),
    TopicIdType = ?SHORT_TOPIC_NAME,
    TopicIdOrName = "tn",
    MaxQos = ?QOS_0,
    emqttsn:subscribe(Client, TopicIdType, TopicIdOrName, MaxQos, false),

    % wait until timeout
    timer:sleep(200),
    emqttsn:finalize(Client).

t_unsubscribe_timeout(_Cfg) ->
    % make state machine start from fake connected
    ok = meck:new(emqttsn_state, [passthrough, no_history, no_link]),
    meck:expect(emqttsn_state,
                init,
                fun({Name, Port, Config}) ->
                   {ok, Socket} = emqttsn_udp:init_port(Port),
                   emqttsn_udp:connect(Socket, ?HOST, ?PORT),
                   {ok,
                    connected,
                    #state{name = Name,
                           socket = Socket,
                           config = Config}}
                end),

    % set a short timeout interval to let it resend
    {ok, Client, _} =
        emqttsn:start_link("UnsubTimeout", [{ack_timeout, 10}, {max_resend, 5}]),
    TopicIdType = ?SHORT_TOPIC_NAME,
    TopicIdOrName = "tn",
    emqttsn:unsubscribe(Client, TopicIdType, TopicIdOrName, false),

    % wait until timeout
    timer:sleep(200),
    emqttsn:finalize(Client).

t_recv_pingreq(_Cfg) ->
    % make state machine start from fake connected
    ok = meck:new(emqttsn_state, [passthrough, no_history, no_link]),
    meck:expect(emqttsn_state,
                init,
                fun({Name, Port, Config}) ->
                   {ok, Socket} = emqttsn_udp:init_port(Port),
                   emqttsn_udp:connect(Socket, ?HOST, ?PORT),
                   {ok,
                    connected,
                    #state{name = Name,
                           socket = Socket,
                           config = Config}}
                end),

    {ok, Client, _} = emqttsn:start_link("RecvPingreq"),
    #state{socket = Socket} = emqttsn:get_state(Client),

    Packet = ?PINGREQ_PACKET(),
    Bin = emqttsn_frame:serialize(Packet, #config{}),
    spawn(emqttsn_udp_SUITE, sender, [Client, {udp, Socket, ?HOST, ?PORT, Bin}]),
    timer:sleep(200),
    emqttsn:finalize(Client).

t_send_pingreq(_Cfg) ->
    % make state machine start from fake connected
    ok = meck:new(emqttsn_state, [passthrough, no_history, no_link]),
    meck:expect(emqttsn_state,
                init,
                fun({Name, Port, Config}) ->
                   {ok, Socket} = emqttsn_udp:init_port(Port),
                   emqttsn_udp:connect(Socket, ?HOST, ?PORT),
                   {ok,
                    connected,
                    #state{name = Name,
                           socket = Socket,
                           config = Config}}
                end),

    % set a short timeout interval to let it resend
    {ok, Client, _} = emqttsn:start_link("SendPingreq", [{keep_alive, 10}]),
    #state{socket = Socket} = emqttsn:get_state(Client),
    Packet = ?PINGRESP_PACKET(),
    Bin = emqttsn_frame:serialize(Packet, #config{}),
    spawn(emqttsn_udp_SUITE, recv_sender, [Client, {udp, Socket, ?HOST, ?PORT, Bin}]),

    timer:sleep(200),
    emqttsn:finalize(Client).

t_pub_qos1_rc_failed(_Cfg) ->
    TopicIdOrName = "tn",
    % make state machine start from fake connected
    ok = meck:new(emqttsn_state, [passthrough, no_history, no_link]),
    meck:expect(emqttsn_state,
                init,
                fun({Name, Port, Config}) ->
                   {ok, Socket} = emqttsn_udp:init_port(Port),
                   emqttsn_udp:connect(Socket, ?HOST, ?PORT),
                   {ok,
                    connected,
                    #state{name = Name,
                           socket = Socket,
                           config = Config,
                           topic_id_use_qos = dict:from_list([{1, ?QOS_1}]),
                           topic_name_id = dict:from_list([{TopicIdOrName, 1}])}}
                end),

    {ok, Client, _} = emqttsn:start_link("PubQos1RcFailed", [{pub_qos, ?QOS_1}]),
    #state{socket = Socket} = emqttsn:get_state(Client),
    Retain = false,
    TopicIdType = ?SHORT_TOPIC_NAME,
    Message = "mess",
    emqttsn:publish(Client, Retain, TopicIdType, TopicIdOrName, Message, false),

    % gateway return a UNSUPPORTED return code
    timer:sleep(200),
    TopicId = 16#01,
    PacketId = 0,

    Packet = ?PUBACK_PACKET(TopicId, PacketId, ?RC_UNSUPPORTED),
    Bin = emqttsn_frame:serialize(Packet, #config{}),
    spawn(emqttsn_udp_SUITE, sender, [Client, {udp, Socket, ?HOST, ?PORT, Bin}]),

    timer:sleep(200),
    emqttsn:finalize(Client).

t_pub_qos1_timeout(_Cfg) ->
    TopicIdOrName = "tn",
    % make state machine start from fake connected
    ok = meck:new(emqttsn_state, [passthrough, no_history, no_link]),
    meck:expect(emqttsn_state,
                init,
                fun({Name, Port, Config}) ->
                   {ok, Socket} = emqttsn_udp:init_port(Port),
                   emqttsn_udp:connect(Socket, ?HOST, ?PORT),
                   {ok,
                    connected,
                    #state{name = Name,
                           socket = Socket,
                           config = Config,
                           topic_id_use_qos = dict:from_list([{1, ?QOS_1}]),
                           topic_name_id = dict:from_list([{TopicIdOrName, 1}])}}
                end),

    % set a short timeout interval to let it resend
    {ok, Client, _} =
        emqttsn:start_link("PubQos1Timeout",
                           [{pub_qos, ?QOS_1}, {ack_timeout, 10}, {max_resend, 5}]),
    Retain = false,
    TopicIdType = ?SHORT_TOPIC_NAME,

    Message = "mess",
    emqttsn:publish(Client, Retain, TopicIdType, TopicIdOrName, Message, false),

    % wait until timeout
    timer:sleep(200),
    emqttsn:finalize(Client).

t_pub_qos2_pub_timeout(_Cfg) ->
    [].

t_pub_qos2_pubrel_timeout(_Cfg) ->
    [].

t_pub_qos2_pubrec_timeout(_Cfg) ->
    [].