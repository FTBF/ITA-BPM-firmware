
CC=avr-gcc
CPP=avr-g++
LD=avr-g++

CCFLAGS=-O1 -mmcu=attiny85 -DF_CPU=1000000UL -ffunction-sections

all : main.hex generate_SYZYGY_DNA_EEPROM_data

main.hex : main.out
	avr-objcopy -O ihex -j.text -j.data $< $@

main.out : main.o usi_i2c_slave.o
	${LD} ${CCFLAGS} $^ -o $@

main.o : main.c
	${CC} ${CCFLAGS} -c $^ -o $@

usi_i2c_slave.o : usi_i2c_slave.c
	${CC} ${CCFLAGS} -c $^ -o $@

#%.o : USIWire/src/%.cpp
#	${CPP} ${CCFLAGS} -c -IUSIWire/src/ $^ -o $@

#%.o : USIWire/src/USI_TWI_Slave/%.c
#	${CC} ${CCFLAGS} -c -IUSIWire/src/ $^ -o $@

#%.o : USIWire/src/USI_TWI_Master/%.c
#	${CC} ${CCFLAGS} -c -IUSIWire/src/ $^ -o $@

main.c : SYZYGY_DNA_EEPROM.h

#USIWire/src/USIWire.cpp : USIWire/src/USIWire.h

#USIWire/src/USI_TWI_Master/USI_TWI_Master.c : USIWire/src/USI_TWI_Master/USI_TWI_Master.h USIWire/src/common/usi_io.h

#USIWire/src/USI_TWI_Slave/USI_TWI_Slave.c : USIWire/src/USI_TWI_Slave/USI_TWI_Slave.h USIWire/src/common/usi_io.h

generate_SYZYGY_DNA_EEPROM_data : generate_SYZYGY_DNA_EEPROM_data.cpp
	g++ -std=c++17 $^ -o $@

clean:
	rm -f *.o *.hex *.out generate_SYZYGY_DNA_EEPROM_data
