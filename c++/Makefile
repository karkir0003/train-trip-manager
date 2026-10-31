CXX ?= $(shell command -v clang++ >/dev/null 2>&1 && echo clang++ || echo g++)
CXXFLAGS ?= -std=c++17 -Wall -Wextra -O2
TARGET = trip_manager
SRCS = trip_manager.cpp

.PHONY: all run build setup clean

all: run

build: $(TARGET)

$(TARGET): $(SRCS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SRCS)

run: $(TARGET)
	@./$(TARGET)

setup:
	@./setup.sh

clean:
	@rm -f $(TARGET) *.o
