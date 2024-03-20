#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define PORTA 12345
#define PORTB 12346

int main()
{
    int serversockA, serversockB;
    struct sockaddr_in server_addressA, server_addressB, client_addressA, client_addressB, clientA, clientB;
    socklen_t client_address_len = sizeof(client_addressA);
    socklen_t client_address_lenA = sizeof(client_addressA);
    socklen_t client_address_lenB = sizeof(client_addressB);
    char buffer[1024];
    char buffer2[1024];

    // Create a UDP socket
    serversockA = socket(AF_INET, SOCK_DGRAM, 0);
    if (serversockA == -1)
    {
        perror("Error creating socket");
        exit(EXIT_FAILURE);
    }

    serversockB = socket(AF_INET, SOCK_DGRAM, 0);
    if (serversockB == -1)
    {
        perror("Error creating socket");
        exit(EXIT_FAILURE);
    }

    server_addressA.sin_family = AF_INET;
    server_addressA.sin_port = htons(PORTA);
    server_addressA.sin_addr.s_addr = INADDR_ANY;

    server_addressB.sin_family = AF_INET;
    server_addressB.sin_port = htons(PORTB);
    server_addressB.sin_addr.s_addr = INADDR_ANY;

    // Bind the socket to a specific address and port
    if (bind(serversockA, (struct sockaddr *)&server_addressA, sizeof(server_addressA)) == -1)
    {
        perror("Error binding socket");
        close(serversockA);
        exit(EXIT_FAILURE);
    }

    if (bind(serversockB, (struct sockaddr *)&server_addressB, sizeof(server_addressB)) == -1)
    {
        perror("Error binding socket");
        close(serversockB);
        exit(EXIT_FAILURE);
    }

    printf("Server listening on ports %d and %d...\n", PORTA, PORTB);

    // printf("Sup");
    int avalue = 3, bvalue = 3;
    int adone = 0, bdone = 0;
    for (int i = 0; i < 5; i++)
    {
        // Receive data from a client
        int received_data = recvfrom(serversockA, buffer, 1024, 0, (struct sockaddr *)&client_addressA, &client_address_lenA);
        if (received_data == -1)
        {
            perror("Error receiving data");
            close(serversockA);
            exit(EXIT_FAILURE);
        }
        buffer[received_data] = '\0';
        printf("Received from client at %s:%d: %s\n", inet_ntoa(client_addressA.sin_addr), ntohs(client_addressA.sin_port), buffer);

        int received_data2 = recvfrom(serversockB, buffer2, 1024, 0, (struct sockaddr *)&client_addressB, &client_address_lenB);
        if (received_data2 == -1)
        {
            perror("Error receiving data");
            close(serversockB);
            exit(EXIT_FAILURE);
        }
        buffer2[received_data2] = '\0';

        printf("Received from client at %s:%d: %s\n", inet_ntoa(client_addressB.sin_addr), ntohs(client_addressB.sin_port), buffer2);
        avalue = atoi(buffer);
        bvalue = atoi(buffer2);
        if (avalue == bvalue)
        {
            strcpy(buffer, "Tie.\n");
            int sent_data = sendto(serversockA, buffer, strlen(buffer), 0, (struct sockaddr *)&client_addressA, client_address_lenA);
            if (sent_data == -1)
            {
                perror("Can't send data");
                close(serversockA);
                exit(EXIT_FAILURE);
            }
            int sent_data2 = sendto(serversockB, buffer, strlen(buffer), 0, (struct sockaddr *)&client_addressB, client_address_lenB);
            if (sent_data2 == -1)
            {
                perror("Can't send data");
                close(serversockB);
                exit(EXIT_FAILURE);
            }
        }
        else if ((avalue == 0 && bvalue == 2) || (avalue == 1 && bvalue == 0) || (avalue == 2 && bvalue == 1))
        {
            strcpy(buffer, "Win.\n");
            strcpy(buffer2, "Lose.\n");

            int sent_data = sendto(serversockA, buffer, strlen(buffer), 0, (struct sockaddr *)&client_addressA, client_address_lenA);
            if (sent_data == -1)
            {
                perror("Can't send data");
                close(serversockA);
                exit(EXIT_FAILURE);
            }
            int sent_data2 = sendto(serversockB, buffer2, strlen(buffer2), 0, (struct sockaddr *)&client_addressB, client_address_lenB);
            if (sent_data2 == -1)
            {
                perror("Can't send data");
                close(serversockB);
                exit(EXIT_FAILURE);
            }
        }
        else if ((bvalue == 0 && avalue == 2) || (bvalue == 1 && avalue == 0) || (bvalue == 2 && avalue == 1))
        {
            strcpy(buffer, "Lose.\n");
            strcpy(buffer2, "Win.\n");

            int sent_data = sendto(serversockA, buffer, strlen(buffer), 0, (struct sockaddr *)&client_addressA, client_address_lenA);
            if (sent_data == -1)
            {
                perror("Can't send data");
                close(serversockA);
                exit(EXIT_FAILURE);
            }
            int sent_data2 = sendto(serversockB, buffer2, strlen(buffer2), 0, (struct sockaddr *)&client_addressB, client_address_lenB);
            if (sent_data2 == -1)
            {
                perror("Can't send data");
                close(serversockB);
                exit(EXIT_FAILURE);
            }
        }
        else
        {
            strcpy(buffer, "Erroneous input.\n");
            int sent_data = sendto(serversockA, buffer, strlen(buffer), 0, (struct sockaddr *)&client_addressA, client_address_lenA);
            if (sent_data == -1)
            {
                perror("Can't send data");
                close(serversockA);
                exit(EXIT_FAILURE);
            }
            int sent_data2 = sendto(serversockB, buffer, strlen(buffer), 0, (struct sockaddr *)&client_addressB, client_address_lenB);
            if (sent_data2 == -1)
            {
                perror("Can't send data");
                close(serversockB);
                exit(EXIT_FAILURE);
            }
        }

        // flagDone = 1;
        printf("Response sent to client\n");

        received_data = recvfrom(serversockA, buffer, sizeof(buffer), 0, (struct sockaddr *)&client_addressA, &client_address_lenA);
        if (received_data == -1)
        {
            perror("Error receiving data");
            close(serversockA);
            exit(EXIT_FAILURE);
        }

        buffer[received_data] = '\0';

        printf("Received from client at %s:%d: %s\n", inet_ntoa(client_addressA.sin_addr), ntohs(client_addressA.sin_port), buffer);

        received_data2 = recvfrom(serversockB, buffer2, sizeof(buffer2), 0, (struct sockaddr *)&client_addressB, &client_address_lenB);
        if (received_data2 == -1)
        {
            perror("Error receiving data");
            close(serversockB);
            exit(EXIT_FAILURE);
        }

        buffer2[received_data2] = '\0';
        printf("Received from client at %s:%d: %s\n", inet_ntoa(client_addressB.sin_addr), ntohs(client_addressB.sin_port), buffer2);
        adone = 0, bdone = 0;
        // if (flagDone == 1)
        // {

        if (strcmp(buffer, "Yes") == 0)
            adone = 1;
        if (strcmp(buffer2, "Yes") == 0)
            bdone = 1;
        // printf("%d %d",adone,bdone);
        if (adone == 0 || bdone == 0)
        {
            strcpy(buffer, "End");
        }
        else
        {
            strcpy(buffer, "Continue\n");
        }
        int sent_data = sendto(serversockA, buffer, strlen(buffer), 0, (struct sockaddr *)&client_addressA, client_address_lenA);
        if (sent_data == -1)
        {
            perror("Can't send data");
            close(serversockA);
            exit(EXIT_FAILURE);
        }
        int sent_data2 = sendto(serversockB, buffer, strlen(buffer), 0, (struct sockaddr *)&client_addressB, client_address_lenB);
        if (sent_data2 == -1)
        {
            perror("Can't send data");
            close(serversockB);
            exit(EXIT_FAILURE);
        }
        if (strcmp(buffer, "End") == 0)
            exit(1);
        avalue = 3, bvalue = 3;
        //  flagDone = 0, flagstoredA = 0, flagstoredB = 0, avalue = 3, bvalue = 3, clientAaddr = 0, flagAdone = 0, flagBdone = 0;

        // Send a response back to the client
        // printf("Enter a message to send to the client: ");
        // fgets(buffer, sizeof(buffer), stdin);
        // buffer[strlen(buffer) - 1] = '\0'; // Remove the newline character

        // Send data to the client

        //  sleep(2);
    }

    // The server should never reach this point
    // close(serversockA);
    // close(serversockB);

    return 0;
}
