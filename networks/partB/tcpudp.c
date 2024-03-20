#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include "time.h"

typedef struct
{
    int chunk_number;
    char data[1024];
} Packet;

#define TIMEOUT 100000
int isTimerExpired(clock_t startTime)
{
    clock_t currentTime = clock();
    return (currentTime - startTime) >= TIMEOUT;
}

int main()
{
    int serversock;
    struct sockaddr_in server_address, client_address;
    socklen_t client_address_len = sizeof(client_address);

    // create socket
    serversock = socket(AF_INET, SOCK_DGRAM, 0);
    if (serversock == -1)
    {
        perror("Error creating socket");
        exit(EXIT_FAILURE);
    }

    // configure address
    // memset(&server_address, 0, sizeof(server_address));
    server_address.sin_family = AF_INET;
    server_address.sin_addr.s_addr = INADDR_ANY;
    server_address.sin_port = htons(12345);

    if (bind(serversock, (struct sockaddr *)&server_address, sizeof(server_address)) == -1)
    {
        perror("Error binding socket");
        close(serversock);
        exit(EXIT_FAILURE);
    }
    printf("Server listening on port 12345...\n");

    char buffer1[1024];
    recvfrom(serversock, &buffer1, sizeof(buffer1), 0, (struct sockaddr *)&client_address, &client_address_len);
    // printf("%s\n",buffer1);

    int expected = 0;
    struct timeval timeout;
    fd_set read_fds;

    char maindata[1024];
    while (1)
    {
        //*************************Sending code*************************

        clock_t timerStart = clock();
        printf("Enter data to be sent: ");
        fgets(maindata, sizeof(maindata), stdin);
        maindata[strlen(maindata) - 1] = '\0';
        int chunksize = 5;
        int indexmain = 0;
        int j = 0;
        char *chunks = (char *)malloc(sizeof(char) * (chunksize + 1));
        int chunkind = 0;

        int isdiv = strlen(maindata) % 5;
        int totaln = 0;
        if (isdiv != 0)
            totaln = strlen(maindata) / 5 + 1;
        else
            totaln = strlen(maindata) / 5;

        int acks[totaln];
        char *chunksarray[totaln];
        for (int i = 0; i < totaln; i++)
        {
            acks[i] = 0;
            chunksarray[i] = (char *)malloc(sizeof(char) * 6);
        }
        Packet buffer;
        timerStart = clock();
        sendto(serversock, &totaln, sizeof(int), 0, (struct sockaddr *)&client_address, client_address_len);
        printf("Number of chunks sent to client with data: %d\n", totaln);
        int i = 0;
        for (i = 0; maindata[indexmain] != '\0'; i++)
        {

            buffer.chunk_number = i;
            chunkind = 0;
            for (j = indexmain; j < indexmain + chunksize; j++)
            {
                if (maindata[j] == '\0')
                    break;
                chunks[chunkind++] = maindata[j];
            }
            chunks[chunkind] = '\0';
            indexmain = j;
            sprintf(buffer.data, "%s", chunks);

            // check for incoming packets
            // FD_ZERO(&read_fds);
            // FD_SET(serversock, &read_fds);
            // timeout.tv_sec = 2;
            // timeout.tv_usec = 0;

            sendto(serversock, &buffer, sizeof(Packet), 0, (struct sockaddr *)&client_address, client_address_len);
            printf("Sequence number %d sent to client with data: %s\n", i, buffer.data);
            strcpy(chunksarray[buffer.chunk_number], chunks);

            recvfrom(serversock, &buffer, sizeof(Packet), 0,(struct sockaddr *)&client_address, &client_address_len);
            while (1)
            {
                if (strcmp(buffer.data, "Ack") == 0)
                {
                    //printf("%d", buffer.chunk_number);
                    acks[buffer.chunk_number] = 1;
                    break;
                }
                if (isTimerExpired(timerStart))
                {
                    acks[buffer.chunk_number]=0;
                    // Timeout occurred
                    timerStart = clock(); // Restart the timer
                    break;
                }
            }
        }
        sleep(0.3);
        //Retransmission
        for (int i = 0; i < totaln; i++)
        {
            if (acks[i] == 0)
            {
                buffer.chunk_number = i;
                sprintf(buffer.data, "%s", chunksarray[i]);
                sendto(serversock, &buffer, sizeof(Packet), 0, (struct sockaddr *)&client_address, client_address_len);
                printf("retransmitting packet with sequence number: %d\n", buffer.chunk_number);
            }
        }

        //*********************Receiving Code:***********************

        totaln = 0;
        int nuacks=0;
        recvfrom(serversock, &totaln, sizeof(int), 0, (struct sockaddr *)&client_address, &client_address_len);
        printf("Received total number of chunks: %d\n", totaln);
        char *chunks2[totaln];
        for (int i = 0; i < totaln; i++)
        {
            chunks2[i] = (char *)malloc(sizeof(char) * 6);
        }
        int count = 0;
        for (int i = 0; i < totaln; i++)
        {
            // printf("HI");
            recvfrom(serversock, &buffer, sizeof(Packet), 0,(struct sockaddr *)&client_address, &client_address_len);
            // printf("%s",buffer.data);

            // if (strcmp(buffer.data, "End") == 0) // when all data has been sent
            // {
            //     close(clientsock);
            //     return 0;
            // }

            if (rand() % 3 != 0)
            {
                nuacks++;
                printf("received data with sequence number %d: %s\n", buffer.chunk_number, buffer.data);
                strcpy(chunks2[buffer.chunk_number], buffer.data);
                Packet packet;
                packet.chunk_number = buffer.chunk_number;
                strcpy(packet.data, "Ack");
                int sent_data = sendto(serversock, &packet, sizeof(Packet), 0, (struct sockaddr *)&client_address, client_address_len);
                if (sent_data == -1)
                {
                    printf("Can't send data");
                    close(serversock);
                    exit(EXIT_FAILURE);
                }
                printf("sent ACK  with sequence number %d\n", packet.chunk_number);
            }
            else
            {
                Packet packet;
                packet.chunk_number = buffer.chunk_number;
                strcpy(packet.data, "Not Ack");
                int sent_data = sendto(serversock, &packet, sizeof(Packet), 0, (struct sockaddr *)&client_address, client_address_len);
                if (sent_data == -1)
                {
                    printf("Can't send data");
                    close(serversock);
                    exit(EXIT_FAILURE);
                }
                // printf("sent NOT ACK  with sequence number %d\n", packet.chunk_number);
            }
        }
        sleep(0.3);
       // printf("%d %d",nuacks,totaln);
       //Receiving retransmission
        for (; nuacks < totaln; nuacks++)
        {
            recvfrom(serversock, &buffer, sizeof(Packet), 0,(struct sockaddr *)&client_address, &client_address_len);
            printf("received data with sequence number %d: %s\n", buffer.chunk_number, buffer.data);
            strcpy(chunks2[buffer.chunk_number], buffer.data);
        }

        printf("Message received: ");
        for (int i = 0; i < totaln; i++)
            printf("%s", chunks2[i]);
        printf("\n");


        //end?

        printf("Would you like to continue? ");
        fgets(maindata, sizeof(maindata), stdin);
        maindata[strlen(maindata) - 1] = '\0';

        if (strcmp(maindata, "Yes") != 0)
        {
            strcpy(maindata, "End");
            Packet packet;
            packet.chunk_number = i;
            sprintf(packet.data, "%s", maindata);

            int sent_data = sendto(serversock, &packet, sizeof(Packet), 0, (struct sockaddr *)&client_address, client_address_len);
            if (sent_data == -1)
            {
                printf("Can't send data");
                close(serversock);
                exit(EXIT_FAILURE);
            }
            close(serversock);

            return 0;
        }
        else{
            strcpy(maindata, "Continuing");
            Packet packet;
            packet.chunk_number = i;
            sprintf(packet.data, "%s", maindata);
            int sent_data = sendto(serversock, &packet, sizeof(Packet), 0, (struct sockaddr *)&client_address, client_address_len);
            if (sent_data == -1)
            {
                printf("Can't send data");
                close(serversock);
                exit(EXIT_FAILURE);
            }
        }
    }

    strcpy(maindata, "End");
    Packet packet;
    packet.chunk_number = -1;
    sprintf(packet.data, "%s", maindata);

    int sent_data = sendto(serversock, &packet, sizeof(Packet), 0, (struct sockaddr *)&client_address, client_address_len);
    if (sent_data == -1)
    {
        printf("Can't send data");
        close(serversock);
        exit(EXIT_FAILURE);
    }
    close(serversock);

    return 0;
}
