#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define PORTA 12345
#define PORTB 12346

int main()
{
    int serversockA, serversockB, clientA, clientB;
    struct sockaddr_in server_addressA, server_addressB, client_addressA, client_addressB;
    socklen_t client_address_len = sizeof(client_addressA);
    socklen_t client_address_lenA = sizeof(client_addressA);
    socklen_t client_address_lenB = sizeof(client_addressB);
    char buffer[1024];
    char buffer2[1024];

    // Create a TCP socket
    serversockA = socket(AF_INET, SOCK_STREAM, 0);
    if (serversockA == -1)
    {
        perror("Error creating socket");
        exit(EXIT_FAILURE);
    }

    serversockB = socket(AF_INET, SOCK_STREAM, 0);
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

    // Listen for incoming connections
    if (listen(serversockA, 5) == -1) // maximum length to which the queue of pending connections for sockfd may grow.
    {
        perror("Error listening");
        close(serversockA);
        close(serversockB);
        exit(EXIT_FAILURE);
    }
    if (listen(serversockB, 5) == -1) // maximum length to which the queue of pending connections for sockfd may grow.
    {
        perror("Error listening");
        close(serversockA);
        close(serversockB);
        exit(EXIT_FAILURE);
    }

    printf("Server listening on ports %d and %d...\n", PORTA, PORTB);

    clientA = accept(serversockA, (struct sockaddr *)&client_addressA, &client_address_lenA);
    if (clientA == -1)
    {
        perror("Can't accept connection");
        close(serversockA);
        exit(EXIT_FAILURE);
    }

    clientB = accept(serversockB, (struct sockaddr *)&client_addressB, &client_address_lenB);
    if (clientB == -1)
    {
        perror("Can't accept connection");
        close(serversockB);
        exit(EXIT_FAILURE);
    }

    // Accept incoming connections

    // printf("Connected to client\n");
    int flagstoredA = 0;
    int flagstoredB = 0;
    int avalue = 3, bvalue = 3;
    int flagDone = 0;
    int clientAaddr;
    int flagAdone = 0, flagBdone = 0;
    int adone = 0, bdone = 0;
    int flagdonecount = 0;

    while (1)
    {

        // Receive data from client
        int received_data = recv(clientA, buffer, sizeof(buffer), 0);
        if (received_data == -1)
        {
            perror("Can't receive data");
            close(clientA);
            close(clientB);
            close(serversockA);
            close(serversockB);
            exit(EXIT_FAILURE);
        }

        buffer[received_data] = '\0';
        printf("Received from client: %s\n", buffer);

        int received_data2 = recv(clientB, buffer2, sizeof(buffer2), 0);
        if (received_data2 == -1)
        {
            perror("Can't receive data");
            close(clientA);
            close(clientB);
            close(serversockA);
            close(serversockB);
            exit(EXIT_FAILURE);
        }

        buffer2[received_data2] = '\0';
        printf("Received from client: %s\n", buffer2);

        // printf("*%d*",flagDone);
        // if (flagDone == 1)
        // {

        // }
        // else
        // {
        avalue = atoi(buffer);
        flagstoredA = 1;
        bvalue = atoi(buffer2);
        flagstoredB = 1;
        // printf("Client B stored\n");
        // ROCK : 0
        // PAPER : 1
        // SCISSOR : 2
        if (avalue == bvalue)
        {
            strcpy(buffer, "Tie.\n");
            int sent_data = send(clientA, buffer, strlen(buffer), 0);
            if (sent_data == -1)
            {
                perror("Can't send data");
                close(clientA);
                close(clientB);
                close(serversockA);
                close(serversockB);
                exit(EXIT_FAILURE);
            }
            printf("Response sent to clientA\n");
            int sent_data2 = send(clientB, buffer, strlen(buffer), 0);
            if (sent_data2 == -1)
            {
                perror("Can't send data");
                close(clientA);
                close(clientB);
                close(serversockA);
                close(serversockB);
                exit(EXIT_FAILURE);
            }
        }
        else if ((avalue == 0 && bvalue == 2) || (avalue == 1 && bvalue == 0) || (avalue == 2 && bvalue == 1))
        {
            strcpy(buffer, "Win.\n");
            strcpy(buffer2, "Lose.\n");
            int sent_data = send(clientA, buffer, strlen(buffer), 0);
            if (sent_data == -1)
            {
                perror("Can't send data");
                close(clientA);
                close(clientB);
                close(serversockA);
                close(serversockB);
                exit(EXIT_FAILURE);
            }
            printf("Response sent to clientA\n");
            int sent_data2 = send(clientB, buffer2, strlen(buffer2), 0);
            if (sent_data2 == -1)
            {
                perror("Can't send data");
                close(clientA);
                close(clientB);
                close(serversockA);
                close(serversockB);
                exit(EXIT_FAILURE);
            }
        }
        else if ((bvalue == 0 && avalue == 2) || (bvalue == 1 && avalue == 0) || (bvalue == 2 && avalue == 1))
        {
            strcpy(buffer, "Lose.\n");
            strcpy(buffer2, "Win.\n");
            int sent_data = send(clientA, buffer, strlen(buffer), 0);
            if (sent_data == -1)
            {
                perror("Can't send data");
                close(clientA);
                close(clientB);
                close(serversockA);
                close(serversockB);
                exit(EXIT_FAILURE);
            }
            printf("Response sent to clientA\n");
            int sent_data2 = send(clientB, buffer2, strlen(buffer2), 0);
            if (sent_data2 == -1)
            {
                perror("Can't send data");
                close(clientA);
                close(clientB);
                close(serversockA);
                close(serversockB);
                exit(EXIT_FAILURE);
            }
        }
        else
        {
            strcpy(buffer, "Erroneous input.\n");
            int sent_data = send(clientA, buffer, strlen(buffer), 0);
            if (sent_data == -1)
            {
                perror("Can't send data");
                close(clientA);
                close(clientB);
                close(serversockA);
                close(serversockB);
                exit(EXIT_FAILURE);
            }
            printf("Response sent to clientA\n");
            int sent_data2 = send(clientB, buffer, strlen(buffer), 0);
            if (sent_data2 == -1)
            {
                perror("Can't send data");
                close(clientA);
                close(clientB);
                close(serversockA);
                close(serversockB);
                exit(EXIT_FAILURE);
            }
        }

        flagDone = 1;
        buffer[0] = '\0';
        buffer2[0] = '\0';
        // close(clientA);
        // close(clientB);
        printf("Response sent to clientB\n");

        received_data = recv(clientA, buffer, sizeof(buffer), 0);
        if (received_data == -1)
        {
            perror("Can't receive data");
            close(clientA);
            close(clientB);
            close(serversockA);
            close(serversockB);
            exit(EXIT_FAILURE);
        }

        buffer[received_data] = '\0';
        printf("Received from client: %s\n", buffer);
        if (strcmp(buffer, "Yes") == 0)
            adone = 1;
        // printf("%d %d", adone, bdone);
        received_data2 = recv(clientB, buffer2, sizeof(buffer2), 0);
        if (received_data2 == -1)
        {
            perror("Can't receive data");
            close(clientA);
            close(clientB);
            close(serversockA);
            close(serversockB);
            exit(EXIT_FAILURE);
        }

        buffer2[received_data2] = '\0';
        if (strcmp(buffer2, "Yes") == 0)
            bdone = 1;
        // printf("%d %d", adone, bdone);
        printf("Received from client: %s\n", buffer2);
        // printf("HHIIIII");

        // printf("%d %d", adone, bdone);
        if (adone == 0 || bdone == 0)
        {
            strcpy(buffer, "End");
        }
        else
        {
            strcpy(buffer, "Continue");
        }
        int sent_data = send(clientA, buffer, strlen(buffer), 0);
        if (sent_data == -1)
        {
            perror("Can't send data");
            close(clientA);
            close(clientB);
            close(serversockA);
            close(serversockB);
            exit(EXIT_FAILURE);
        }
        int sent_data2 = send(clientB, buffer, strlen(buffer), 0);
        if (sent_data2 == -1)
        {
            perror("Can't send data");
            close(clientA);
            close(clientB);
            close(serversockA);
            close(serversockB);
            exit(EXIT_FAILURE);
        }
        if (strcmp(buffer, "End") == 0)
            exit(1);

        flagDone = 0, flagstoredA = 0, flagstoredB = 0, avalue = 3, bvalue = 3, clientAaddr = 0, flagAdone = 0, flagBdone = 0, adone = 0, bdone = 0;
        //}

        sleep(2);
    }
    // Close sockets
    close(clientA);
            close(clientB);
    close(serversockA);
    close(serversockB);

    return 0;
}
