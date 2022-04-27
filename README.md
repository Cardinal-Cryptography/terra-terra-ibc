# What

This repository contains the necessary blocks that are required to run an IBC bridge between two Terra chains. This includes:
* A Docker compose file with two Terra networks
* A collection of keys required to submit transactions to both networks.
* A `hermes` config file (`hermes/config.toml`) that defines the chains it can connect to.

Other prerequisities include 
* [hermes](https://hermes.informal.systems/), used for relaying block headers and transactions between two chains. To install `hermes`, please follow the official tutorial.
* Docker and docker compose.
* `terrad` with a version matching local Terra chains (`0.5.14`). `terrad` can be installed from the [official release page](https://github.com/terra-money/core/releases/tag/v0.5.14).

# Why



# How

We assume that you have `hermes` installed and the `--home` directory used is `~/.hermes/`.

0. Copy hermes config file to your hermes directory (`make setup-hermes`) and add Terra keys to it, so that it can use them to submit IBC transactions to both chains: `make add-terra-keys`.
1. Start Terra networks: `make start-terra-networks`
2. In a separate terminal you can play with IBC. You can follow [this guide](https://hermes.informal.systems/tutorials/index.html) but NOTE that our networks are called `localterra-0` and `localterra-1` rather than `ibc-0` and `ibc-1`.

## Mini-tutorial.
### Prerequisite
Start Terra networks: `make start-terra-networks`
### Setup IBC connections

```
hermes create channel localterra-0 localterra-1 --port-a transfer --port-b transfer
```

Will create Tendermint clients on both networks, create connections, channels and ports.

### Start relayer
```
hermes start
```

### Send transfer

#### Check balances

Check balance of the recipient account:
```
ADDRESS=$(cat localterra-0/terra-0-user.json | jq .address | tr -d '"') 
terrad query bank balances $ADDRESS  --node="tcp://localhost:26657"
```

Check balance of the source account:
```
ADDRESS=$(cat localterra-1/terra-1-user.json | jq .address | tr -d '"')
terrad query bank balances $ADDRESS  --node="tcp://localhost:26557"
```
#### Send IBC transfer
```
hermes tx raw ft-transfer localterra-1 localterra-0 transfer channel-0 9999 --denom uusd -o 1000 -n 2
```

Note the `--denom uusd` argument that is not present in the official hermes tutorial. This is because `hermes`, by default, will try to transfer _samoleans_ tokens which are not tokens used on Terra networks. Our users, that we had set up, are funded with `Luna` (`uluna`) and `UST` (`uusd`).

In order to verify that the requested amonunt of tokens have been transferred, execute the `terrad` commands again. 

On `terra-1-user` account (on `localterra-1`), you should see something like this:
```
balances:
- amount: "19998"
  denom: ibc/6F4968A73F90CF7DE6394BF937D6DF7C7D162D74D839C13F53B41157D315E05F
- amount: "1000000000"
  denom: uluna
- amount: "99996755"
  denom: uusd
pagination:
  next_key: null
  total: "0"
```

Notice the `denom: ibc/6F4968A73F90CF7DE6394BF937D6DF7C7D162D74D839C13F53B41157D315E05F` entry. These are the tokens sent from `localterra-0` to `localterra-1`. They're not native to `localterra-1`.

If we now send them back to `localterra-0`:
```
hermes tx raw ft-transfer localterra-0 localterra-1 transfer channel-0 9999 --denom "ibc/6F4968A73F90CF7DE6394BF937D6DF7C7D162D74D839C13F53B41157D315E05F" -o 1000 -n 2
```
and verify the balances:
```
terrad query bank balances terra1up5prmdhas3l0u83xdcfqc6lj49qpsghkvltjr --node="tcp://localhost:26557"
balances:
- amount: "1000000000"
  denom: uluna
- amount: "99996012"
  denom: uusd
pagination:
  next_key: null
  total: "0"
```
on `localterra-1` we no longer have the strange-looking entry. 

And on `localterra-0`:
```
terrad query bank balances "terra1ep0z2usul4cnal6dn9deg2uqfqwt52tksp5al6"
balances:
- amount: "10000000000000000"
  denom: ueur
- amount: "1000000000000000000"
  denom: ukrw
- amount: "1000000000000000"
  denom: uluna
- amount: "10000000000000000"
  denom: usdr
- amount: "9999999999996286"
  denom: uusd
pagination:
  next_key: null
  total: "0"
```

We have `19 452 uusd` more. (_TODO: Where did we loose 500-ish tokens? To figure out the fees._)


-----


## Miscellaneous

Things that I had to read from various docs, code or reverse engineer.

---
### Generating Terra keys.

 In order to generate Terra keys, run `terrad --home <terra home> keys add <key name>`. `<terra home>` is a directory where the key will be stored. For the purpose of this guide, I had created two directories (`localterra-0`, `localterra-1`) and used them independently when generating keys.


 ---
### Setting up your own Terra network.

1. Generate base `genesis.json` file. `terrad --home <terra home> init <moniker> --chain-id <chain-id>`
2. Add Genesis accounts. For every key you wish to include in genesis, run `terrad --home add-genesis-account <key-name> <genesis balances>`

**Example:** `terrad --home localterra-1 localterra-user-1 '1000000uluna,1000000uusd'`

3. Add Genesis validators. We will generate Genesis bond transactions, each signed by a validator we wish to bond at genesis: `terrad --home <terra home> gentx <validator-key-name> <stake> --chain-id <chain-id>`. 

**Example:** `terrad --home localterra-1 gentx localterra-validator-1 10000uluna --chain-id localterra-1`

4. Collect Genesis transactions and update `genesis.json`.

**Example:** `terrad --home localterra-1 collect-gentxs`

5. Now, `genesis.json` is ready to be used in a new network where we will have two Genesis users `localterra-user-1` and `localterra-validator-1` and one validator `localterra-validator-1`.

---
### Adding Terra keys to Hermes.

Format in which `terrad` outputs the keys is not immediately compatible with `hermes`. Apart from `terrad` by default using `text` as output, wheras `hermes` uses JSON files, it also does not output public keys in expected format. 

In order to use previously generated Terra keys with hermes, follow the steps below:

1. Generate Terra keys with `terrad --output json --home <terra keys home> keys add <key-name> | jq | <key-name>.json`.
2. Map Terra PROTO public key into HEX format: `terrad debug pubkey $(cat <key-name>.json | jq .pubkey)` and record `PubKey HEX`.
3. Map Terra HEX key into `bech32`: `terrad keys parse <HEX key>`.
5. Take bech32 version of public key (second from the top, prefix `terrapub`) and put into JSON file of the key under `pubkey` - effectively replacing original Terra PROTO format.
6. Now, key is ready to be imported into hermes: `hermes keys add <chain-id> -f <key-name>.json -p "m/44'/330'/0'/0/0" --name "terra-0-user"`. The `-p` is BIP for Terra keys.

