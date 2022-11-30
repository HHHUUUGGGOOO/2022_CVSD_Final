CC = g++
LDFLAGS = -std=c++0x -O3 -lm
CFLAGS = -c

SOURCES = src/main.cpp src/Utilities.cpp src/Polar_Decoder.cpp
OBJECTS = $(SOURCES:.c=.o)

EXECUTABLE = cvsd
INCLUDES = src/Utilities.h src/Polar_Decoder.h

all: $(SOURCES) bin/$(EXECUTABLE)

bin/$(EXECUTABLE): $(OBJECTS)
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

%.o: %.c ${INCLUDES}
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -rf *.o bin/$(EXECUTABLE)