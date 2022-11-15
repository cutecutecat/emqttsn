CT_NODE_NAME = ct@127.0.0.1

REBAR := $(CURDIR)/rebar3

REBAR_URL := https://github.com/emqx/rebar3/releases/download/3.16.1-emqx-1/rebar3

all: emqttsn

$(REBAR):
	@curl -k -f -L "$(REBAR_URL)" -o ./rebar3
	@chmod +x ./rebar3

emqttsn: $(REBAR) escript
	$(REBAR) as emqttsn release

compile: $(REBAR)
	$(REBAR) compile

unlock:
	$(REBAR) unlock

clean: distclean

distclean:
	@rm -rf _build _packages erl_crash.dump rebar3.crashdump rebar.lock emqttsn_cli rebar3

xref:
	$(REBAR) xref

eunit: compile
	$(REBAR) eunit verbose=true

ct: compile
	$(REBAR) as test ct -v --name $(CT_NODE_NAME)

cover:
	$(REBAR) cover

test: eunit ct cover

dialyzer:
	$(REBAR) dialyzer

escript: $(REBAR) compile
	$(REBAR) as escript escriptize