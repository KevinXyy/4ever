APP_DIR := app
FVM := fvm
FLUTTER := $(FVM) flutter
DART := $(FVM) dart

.PHONY: doctor get analyze test gen run-web clean

doctor:
	cd $(APP_DIR) && $(FLUTTER) doctor

get:
	cd $(APP_DIR) && $(FLUTTER) pub get

analyze:
	cd $(APP_DIR) && $(FLUTTER) analyze

test:
	cd $(APP_DIR) && $(FLUTTER) test

gen:
	cd $(APP_DIR) && $(DART) run build_runner build --delete-conflicting-outputs

run-web:
	cd $(APP_DIR) && $(FLUTTER) run -d chrome

clean:
	cd $(APP_DIR) && $(FLUTTER) clean
