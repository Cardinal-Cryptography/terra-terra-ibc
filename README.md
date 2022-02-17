# What

This repository contains the necessary blocks that are required to run an IBC bridge between two Terra chains. This includes:
* A Docker compose file with two Terra networks
* A collection of keys required to submit transactions to both networks.
* A `hermes` config file (`hermes/config.toml`) that defines the chains it can connect to.

Other prerequisities include 
* [hermes](https://hermes.informal.systems/), used for relaying block headers and transactions between two chains. To install `hermes`, please follow the official tutorial.
* Docker and docker compose.

# Why



# How

We assume that you have `hermes` installed and the `--home` directory used is `~/.hermes/`.

0. Copy hermes config file to your hermes directory (`make setup-hermes`) and add Terra keys to it, so that it can use them to submit IBC transactions to both chains: `make add-terra-keys`.
1. Start Terra networks: `make start-terra-networks`
2. In a separate terminal you can play with IBC. You can follow [this guide](https://hermes.informal.systems/tutorials/index.html) but NOTE that our networks are called `localterra-0` and `localterra-1` rather than `ibc-0` and `ibc-1`.