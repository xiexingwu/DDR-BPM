# To ensure the LSP works, first run the following make target
# then make a build on xcode.
build-server-config:
	xcode-build-server config -project *.xcodeproj
