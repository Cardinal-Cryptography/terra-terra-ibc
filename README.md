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