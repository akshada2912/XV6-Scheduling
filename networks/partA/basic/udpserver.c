#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{
    int serversock;
    struct sockaddr_in server_address, client_address;
    socklen_t client_address_len = sizeof(client_address);
    char buffer[1024];

    // Create a UDP socket
    serversock = socket(AF_INET, SOCK_DGRAM, 0);
    if (serversock == -1)
    {
        printf("Can't create socket");
        exit(EXIT_FAILURE);
    }

    server_address.sin_family = AF_INET;
    server_address.sin_port = htons(12345);
    server_address.sin_addr.s_addr = INADDR_ANY;

    // Bind the socket to a specific address and port
    if (bind(serversock, (struct sockaddr *)&server_address, sizeof(server_address)) == -1)
    {
        printf("Can't bind socket");
        close(serversock);
        exit(EXIT_FAILURE);
    }

    printf("Server listening on port 12345...\n");

    while (1)
    {
        // Receive data from client
        int received_data = recvfrom(serversock, buffer, sizeof(buffer), 0, (struct sockaddr *)&client_address, &client_address_len);
        if (received_data == -1)
        {
            printf("Error receiving data");
            close(serversock);
            exit(EXIT_FAILURE);
        }

        buffer[received_data] = '\0';
        printf("Received from client: %s\n", buffer);

        // Send a response to the client
        printf("Enter a message to send to the client: ");
        fgets(buffer, sizeof(buffer), stdin);
        buffer[strlen(buffer) - 1] = '\0'; // Remove the newline character

        // Send data to the client
        int sent_data = sendto(serversock, buffer, strlen(buffer), 0, (struct sockaddr *)&client_address, client_address_len);
        if (sent_data == -1)
        {
            printf("Can't send data");
            close(serversock);
            exit(EXIT_FAILURE);
        }

        printf("Response sent to client\n");
        sleep(2);
    }

    // The server should never reach this point
    close(serversock);

    return 0;
}
