
CC=avr-g++

CCFLAGS=-Os -mmcu=attiny85 -DF_CPU=1000000UL

all : main.hex

main.hex : main.out
	avr-objcopy -O ihex -j.text -j.data $< $@

main.out : main.c
	${CC} ${CCFLAGS} $^ -o $@

twi.c : twi.h

twi1.c : twi1.h

clean:
	rm -f *.o *.hex *.out
