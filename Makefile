
MODEL ?= Llama-3.2-1B-Instruct-Q4_0.gguf
DEVICE ?= HTP0
PROMPT ?= "What is the capital of France?"
EXTRA_ARGS ?= ""

CONTAINER_NAME = aLlama

.PHONY: run all push clean dir

TARGET_DIR = pkg-adb/llama.cpp
TARGET := $(TARGET_DIR)/bin/llama-cli
BUILD_DIR := build-snapdragon
LLAMA_CPP_DIR := workspace/llama.cpp

ANDROID_TARGET_DIR := /data/local/tmp/

HW_DEVICE := RFCY919LGLD

EXTRA_ARGS += -s $(HW_DEVICE) 

RELATED_SRCS := $(wildcard src/*.h src/*.cpp)
RELATED_SRCS += $(wildcard src/models/*.h src/models/*.cpp)
RELATED_SRCS += $(wildcard ggml/src/ggml-hexagon/*.h ggml/src/ggml-hexagon/*.c ggml/src/ggml-hexagon/*.cpp)
RELATED_SRCS += $(wildcard ggml/src/ggml-hexagon/htp/*.h ggml/src/ggml-hexagon/htp/*.c)
RELATED_SRCS += $(wildcard tools/main/*.h tools/main/*.cpp)

all: $(TARGET)
	-@echo "Build completed: $(TARGET)"
# 	-@echo "Watched sources:"
# 	-@for f in $(RELATED_SRCS); do echo " - $$f"; done

$(TARGET): dir $(RELATED_SRCS)
	-@docker exec -it $(CONTAINER_NAME) bash -c "cd $(LLAMA_CPP_DIR) && cmake --preset arm64-android-snapdragon-release -B build-snapdragon"
	-@docker exec -it $(CONTAINER_NAME) bash -c "cd $(LLAMA_CPP_DIR) && cmake --build build-snapdragon"
	-@docker exec -it $(CONTAINER_NAME) bash -c "cd $(LLAMA_CPP_DIR) && cmake --install build-snapdragon --prefix pkg-adb/llama.cpp"

push: $(TARGET)
	-@adb -s $(HW_DEVICE) push $(TARGET_DIR) $(ANDROID_TARGET_DIR)

run: push
	M=$(MODEL) D=$(DEVICE) ./scripts/snapdragon/adb/run-cli.sh $(EXTRA_ARGS) -no-cnv -p $(PROMPT) | tee run.log

clean:
	-@rm -rf $(TARGET_DIR)
	-@rm -rf $(BUILD_DIR)
	-@rm -rf pkg-adb/llama.cpp

dir:
	-@mkdir -p $(TARGET_DIR)
	-@mkdir -p $(BUILD_DIR)
