/* 
 * File:   main.c
 * Author: pastika
 *
 * Created on September 28, 2022, 3:50 PM
 */

#include <stdio.h>
#include <stdlib.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include "twi.h"
#include "twi1.h"

uint8_t data[2];

//set defaults
const uint8_t NREG = 8;
//vadj_a, vadj_b, vadj_c, NA, NA, NA, NA, SaveSettings
uint8_t config_regs[NREG] = {0xc2, 0xc2, 0x9f, 0x00, 0x00, 0x00, 0x00, 0x00};
uint8_t readback_reg = 0;
//set bits here to apply that register's settings on startup 
uint8_t reg_activity = 0x07;

void setVoltage(uint8_t supply, uint8_t voltage)
{
    uint8_t saddr = 0;

    //set page
    data[0] = 0x00;
    switch(supply)
    {
    case 0:
        data[1] = 0x03;
        saddr = 0x6a;
        break;
    case 1:
        data[1] = 0x02;
        saddr = 0x6a;
        break;
    case 2:
        data[1] = 0x03;
        saddr = 0x69;
        break;
    default:
        //there are only 3 adjustable supplies
        return;
    }
    twi_writeTo(saddr, data, 2, 1, 1);

    //unlock registers
    data[0] = 0x10;
    data[1] = 0x20;
    twi_writeTo(saddr, data, 2, 1, 1);

    //set reference voltage
    data[0] = 0xd8;
    data[1] = voltage;
    twi_writeTo(saddr, data, 2, 1, 1);

    //relock registers
    data[0] = 0x10;
    data[1] = 0x40;
    twi_writeTo(saddr, data, 2, 1, 1);    
}

void saveSettings()
{
    uint8_t saddr1 = 0x69;

    //unlock registers
    data[0] = 0x10;
    data[1] = 0x00;
    twi_writeTo(saddr1, data, 2, 1, 1);

    //set reference voltage
    data[0] = 0x11;
    twi_writeTo(saddr1, data, 1, 1, 1);

    //relock registers
    data[0] = 0x10;
    data[1] = 0x40;
    twi_writeTo(saddr1, data, 2, 1, 1);    

    uint8_t saddr2 = 0x6a;

    //unlock registers
    data[0] = 0x10;
    data[1] = 0x00;
    twi_writeTo(saddr2, data, 2, 1, 1);

    //set reference voltage
    data[0] = 0x11;
    twi_writeTo(saddr2, data, 1, 1, 1);

    //relock registers
    data[0] = 0x10;
    data[1] = 0x40;
    twi_writeTo(saddr2, data, 2, 1, 1);    
}


void recvFromZYNQ_Callback(uint8_t * data, int size)
{
    if(size >= 1) readback_reg         = data[0];
    if(size >= 2)
    {
        switch(data[0])
        {
        case 0:
        case 1:
        case 2:
        case 7:
            config_regs[data[0]] = data[1];
            reg_activity |= 1 << data[0];
            break;
        default:
            break;
        }
    }
}

void replyToZYNQ_Callback()
{
    switch(readback_reg)
    {
    case 0:
    case 1:
    case 2:
        twi_transmit1(config_regs + readback_reg, 1);
        break;
    case 3:
        data[0] = PORTD;
        twi_transmit1(data, 1);
        break;
    default:
        twi_transmit1(NULL, 0);
        break;
    }
}

int main(int argc, char** argv)
{
    //enable global interrupt
    sei();

    //initialize i2c interface to control voltage regulators
    twi_init();

    //initialize i2c interface to talk to ZYNQ
    twi_init1();

    //register device address 0x60
    twi_setAddress1(0x60);

    //register interrupt handlers
    twi_attachSlaveRxEvent1(recvFromZYNQ_Callback);
    twi_attachSlaveTxEvent1(replyToZYNQ_Callback);

    // set voltage enable bits on port C to outputs
    PORTC &= ~0xe;
    DDRC = 0xe;

    //set port D to input
    DDRD = 0x00;
    
    while(1)
    {
        for(uint8_t iReg = 1; iReg; iReg <<= 1)
        {
            if(reg_activity & iReg)
            {
                reg_activity &= ~iReg;
                switch(iReg)
                {
                case 0x01:
                    setVoltage(0, 0x7f & config_regs[0]);
                    if(config_regs[0] & 0x80) PORTC |= 0x2;
                    else                      PORTC &= ~0x2;
                    break;
                case 0x02:
                    setVoltage(1, 0x7f & config_regs[1]);
                    if(config_regs[1] & 0x80) PORTC |= 0x4;
                    else                      PORTC &= ~0x4;
                    break;
                case 0x04:
                    setVoltage(2, 0x7f & config_regs[2]);
                    if(config_regs[2] & 0x80) PORTC |= 0x8;
                    else                      PORTC &= ~0x8;
                    break;
                case 0x80:
                    if(config_regs[7] == 0xd2) saveSettings();
                    break;
                default:
                    break;
                }
            }
        }
    }
    
    return (EXIT_SUCCESS);
}

