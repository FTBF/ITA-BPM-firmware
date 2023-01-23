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

int main(int argc, char** argv)
{

    // set voltage enable bits on port B to outputs
    DDRB = 0x00;
    PORTB = 0x00;

    // configure ADC for operation
    ADMUX = 0x92;
    ADCSRA = 0x83;
    DIDR0 = 0x00;

    while(1)
    {
    }
    
    return (EXIT_SUCCESS);
}

