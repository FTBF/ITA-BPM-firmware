/* 
 * File:   main.c
 * Author: pastika
 *
 * Created on September 28, 2022, 3:50 PM
 */

#include "usi_i2c_slave.h"

#include <stdio.h>
#include <stdlib.h>
#include <avr/io.h>
#include <avr/interrupt.h>

//void USI_request()
//{
//    Wire.write(0xab);
//}
//
//void USI_recieve(int n)
//{
//    //while (Wire.available()) Wire.read();
//}

void initADC()
{
    // configure ADC for operation
    ADMUX = 0x03;
    ADCSRA = 0xd3;
    DIDR0 = 0x08;
}

void waitForADC()
{
    // configure ADC for operation
    while(!(ADCSRA & 0x10));
}

uint8_t returnI2CAddr()
{
    //read ADC value
    uint16_t adcval = 0;
    adcval |= ADCL;
    adcval |= (ADCH << 8);

    uint8_t i2cAddr = 0x30;
    if     (adcval > 945) return i2cAddr;
    else if(adcval > 881) return i2cAddr+1;
    else if(adcval > 820) return i2cAddr+2;
    else if(adcval > 758) return i2cAddr+3;
    else if(adcval > 694) return i2cAddr+4;
    else if(adcval > 630) return i2cAddr+5;
    else if(adcval > 567) return i2cAddr+6;
    else if(adcval > 507) return i2cAddr+7;
    else if(adcval > 446) return i2cAddr+8;
    else if(adcval > 384) return i2cAddr+9;
    else if(adcval > 321) return i2cAddr+10;
    else if(adcval > 259) return i2cAddr+11;
    else if(adcval > 198) return i2cAddr+12;
    else if(adcval > 136) return i2cAddr+13;
    else if(adcval >  76) return i2cAddr+14;
    else                  return i2cAddr+15;
}

int main(int argc, char** argv)
{
    // set voltage enable bits on port B to outputs
    DDRB = 0x0;
    PORTB = 0x0;

//    initADC();
//    waitForADC();
//    uint8_t i2cAddr = returnI2CAddr();

    //initialize interrupts
//    sei();
//    
//    //initialize "i2c"
////    USI_I2C_Init(0x30);
////    Wire.begin(0x30);
////    Wire.onRequest(USI_request);
////    Wire.onReceive(USI_recieve);
//
//    uint8_t last_SDA = 1, last_SCL = 1;
//    uint8_t SDA, SCL;
//    uint8_t datum = 0;;
//    uint8_t count = 0;
//
//    enum State {
//        IDLE,
//        START,
//        ADDR,
//        RW,
//        ACK1,
//        ACK2,
//    } state = IDLE;
//    
    while(1)
    {
//        SDA = (PINB & 0x1)?1:0;
//        SCL = (PINB & 0x4)?1:0;
//
//        switch(state)
//        {
//        case IDLE:
//            if(SCL && last_SCL && !SDA && last_SDA)
//            {
//                //start
//                datum = 0;
//                count = 0;
//                state = START;
//            }
//            break;
//
//        case START:
//            if(SCL && !last_SCL)
//            {
//                datum = (datum << 1) | SDA;
//                ++count;
//                if(count >= 8)
//                {
//                    state = ACK1;
//                    DDRB = 0x1;
//                }
//            }
//            break;
//
//        case ACK1:
//            if(SCL && !last_SCL)
//            {
//                DDRB = 0x0;
//                state = IDLE;
//            }
//            break;
//
//        case ACK2:
//            if(!SCL && last_SCL)
//            {
//                DDRB = 0x0;
//                state = IDLE;
//            }
//            break;            
//            
//        }
//
//        last_SCL = SCL;
//        last_SDA = SDA;
    }
    
    return (EXIT_SUCCESS);
}
