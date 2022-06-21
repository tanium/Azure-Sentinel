.PHONY: all
all: Solutions/Tanium/Packages/1.0.1.zip

Solutions/Tanium/Packages/1.0.1.zip: Tools/Create-Azure-Sentinel-Solution/input/Solution_Tanium.json
	rm -f ./Solutions/Tanium/Package/* && \
	./tanium_scripts/pre-build.sh && \
	./tanium_scripts/fix_playbooks.sh && \
	./tanium_scripts/build.sh && \
	./tanium_scripts/fix_maintemp.sh && \
	./tanium_scripts/fix_createuidef.sh

.PHONY: dev-server
dev-server:
	cd ./Solutions/Tanium && python3 -m http.server
