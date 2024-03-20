#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <time.h>

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
    int clientsock;
    struct sockaddr_in server_address;

    clientsock = socket(AF_INET, SOCK_DGRAM, 0);
    if (clientsock == -1)
    {
        perror("Error creating socket");
        exit(EXIT_FAILURE);
    }

    // memset(&server_address, 0, sizeof(server_address));
    server_address.sin_family = AF_INET;
    server_address.sin_addr.s_addr = inet_addr("127.0.0.1");
    server_address.sin_port = htons(12345);

    srand(time(NULL));
    int sent_data;
    char *buffer1 = "Connected";
    sent_data = sendto(clientsock, &buffer1, sizeof(buffer1), 0, (struct sockaddr *)&server_address, sizeof(server_address));
    int nuacks = 0;
    Packet buffer;
    char maindata[1024];
    while (1)
    {
        //**********************Receiving code*******************
        int totaln = 0;
        nuacks = 0;
        recvfrom(clientsock, &totaln, sizeof(int), 0, NULL, NULL);
        printf("Received total number of chunks: %d\n", totaln);
        char *chunks[totaln];
        for (int i = 0; i < totaln; i++)
        {
            chunks[i] = (char *)malloc(sizeof(char) * 6);
        }
        int count = 0;
        for (int i = 0; i < totaln; i++)
        {
            // printf("HI");
            recvfrom(clientsock, &buffer, sizeof(Packet), 0, NULL, NULL);
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
                strcpy(chunks[buffer.chunk_number], buffer.data);
                Packet packet;
                packet.chunk_number = buffer.chunk_number;
                strcpy(packet.data, "Ack");
                sent_data = sendto(clientsock, &packet, sizeof(Packet), 0, (struct sockaddr *)&server_address, sizeof(server_address));
                if (sent_data == -1)
                {
                    printf("Can't send data");
                    close(clientsock);
                    exit(EXIT_FAILURE);
                }
                printf("sent ACK  with sequence number %d\n", packet.chunk_number);
            }
            else
            {
                Packet packet;
                packet.chunk_number = buffer.chunk_number;
                strcpy(packet.data, "Not Ack");
                sent_data = sendto(clientsock, &packet, sizeof(Packet), 0, (struct sockaddr *)&server_address, sizeof(server_address));
                if (sent_data == -1)
                {
                    printf("Can't send data");
                    close(clientsock);
                    exit(EXIT_FAILURE);
                }
                // printf("sent NOT ACK  with sequence number %d\n", packet.chunk_number);
            }
        }
        sleep(0.3);
        // printf("%d %d",nuacks,totaln);
        for (; nuacks < totaln; nuacks++)
        {
            recvfrom(clientsock, &buffer, sizeof(Packet), 0, NULL, NULL);
            printf("received data with sequence number %d: %s\n", buffer.chunk_number, buffer.data);
            strcpy(chunks[buffer.chunk_number], buffer.data);
        }

        printf("Message received: ");
        for (int i = 0; i < totaln; i++)
            printf("%s", chunks[i]);
        printf("\n");

        //******************Sending code:*************************

        clock_t timerStart = clock();
        printf("Enter data to be sent: ");
        fgets(maindata, sizeof(maindata), stdin);
        maindata[strlen(maindata) - 1] = '\0';
        int chunksize = 5;
        int indexmain = 0;
        int j = 0;
        char *chunks2 = (char *)malloc(sizeof(char) * (chunksize + 1));
        int chunkind = 0;

        int isdiv = strlen(maindata) % 5;
        totaln = 0;
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
        sendto(clientsock, &totaln, sizeof(int), 0, (struct sockaddr *)&server_address, sizeof(server_address));
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
                chunks2[chunkind++] = maindata[j];
            }
            chunks2[chunkind] = '\0';
            indexmain = j;
            sprintf(buffer.data, "%s", chunks2);

            // check for incoming packets
            // FD_ZERO(&read_fds);
            // FD_SET(serversock, &read_fds);
            // timeout.tv_sec = 2;
            // timeout.tv_usec = 0;

            sendto(clientsock, &buffer, sizeof(Packet), 0, (struct sockaddr *)&server_address, sizeof(server_address));
            printf("Sequence number %d sent to client with data: %s\n", i, buffer.data);
            strcpy(chunksarray[buffer.chunk_number], chunks2);

            recvfrom(clientsock, &buffer, sizeof(Packet), 0, NULL, NULL);
            while (1)
            {
                if (strcmp(buffer.data, "Ack") == 0)
                {
                    // printf("%d", buffer.chunk_number);
                    acks[buffer.chunk_number] = 1;
                    break;
                }
                if (isTimerExpired(timerStart))
                {
                    acks[buffer.chunk_number] = 0;
                    // Timeout occurred
                    timerStart = clock(); // Restart the timer
                    break;
                }
            }
        }
        sleep(0.3);
        for (int i = 0; i < totaln; i++)
        {
            if (acks[i] == 0)
            {
                buffer.chunk_number = i;
                sprintf(buffer.data, "%s", chunksarray[i]);
                sendto(clientsock, &buffer, sizeof(Packet), 0, (struct sockaddr *)&server_address, sizeof(server_address));
                printf("retransmitting packet with sequence number: %d\n", buffer.chunk_number);
            }
        }

        // end?
        recvfrom(clientsock, &buffer, sizeof(Packet), 0, NULL, NULL);
        if (strcmp(buffer.data, "End") == 0) // when all data has been sent
        {
            printf("Closing connection\n");
            close(clientsock);
            return 0;
        }
        else
        {
            printf("Continuing\n");
        }
    }

    return 0;
}
