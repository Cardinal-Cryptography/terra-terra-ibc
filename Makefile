.PHONY: start-terra-networks
start-terra-networks:
	docker-compose -f docker-compose.yml up

.PHONY: stop-terra-networks
stop-terra-networks:
	docker-compose stop


.PHONY: setup-hermes
setup-hermes:
	cp hermes/config.toml ~/.hermes/

.PHONY: add-terra-keys
add-terra-keys:
	hermes keys add localterra-0 -f localterra-0/terra-0-user.json \
		-p "m/44'/330'/0'/0/0" --name "terra-0-user" & \
	hermes keys add localterra-1 -f localterra-1/terra-1-user.json \
		-p "m/44'/330'/0'/0/0" --name "terra-1-user"