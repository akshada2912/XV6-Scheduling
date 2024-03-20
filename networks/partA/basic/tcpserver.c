#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{
    int serversock, client;
    struct sockaddr_in server_address, client_address;
    socklen_t client_address_len = sizeof(client_address);
    char buffer[1024];

    // Create a TCP socket
    serversock = socket(AF_INET, SOCK_STREAM, 0);
    if (serversock == -1)
    {
        perror("Error creating socket");
        exit(EXIT_FAILURE);
    }

    server_address.sin_family = AF_INET;
    server_address.sin_port = htons(12345); // set port
    server_address.sin_addr.s_addr = INADDR_ANY;

    // Bind the socket to a specific address and port
    if (bind(serversock, (struct sockaddr *)&server_address, sizeof(server_address)) == -1)
    {
        perror("Can't bind socket");
        close(serversock);
        exit(EXIT_FAILURE);
    }

    // Listen for incoming connections
    if (listen(serversock, 5) == -1) // maximum length to which the queue of pending connections for sockfd may grow.
    {
        perror("Error listening");
        close(serversock);
        exit(EXIT_FAILURE);
    }

    printf("Server listening on port 12345...\n");

    // Accept incoming connections
    client = accept(serversock, (struct sockaddr *)&client_address, &client_address_len);
    if (client == -1)
    {
        perror("Can't accept connection");
        close(serversock);
        exit(EXIT_FAILURE);
    }

    printf("Connected to client\n");
    while (1)
    {
        // Receive data from client
        int received_data = recv(client, buffer, sizeof(buffer), 0);
        if (received_data == -1)
        {
            perror("Can't receive data");
            close(client);
            close(serversock);
            exit(EXIT_FAILURE);
        }

        buffer[received_data] = '\0';
        printf("Received from client: %s\n", buffer);

        // Send a response to the client
        printf("Enter a message to send to the client: ");
        fgets(buffer, sizeof(buffer), stdin);
        buffer[strlen(buffer) - 1] = '\0';

        int sent_data = send(client, buffer, strlen(buffer), 0);
        if (sent_data == -1)
        {
            perror("Can't send data");
            close(client);
            close(serversock);
            exit(EXIT_FAILURE);
        }

        printf("Response sent to client\n");
        sleep(2);
    }
    // Close sockets
    close(client);
    close(serversock);

    return 0;
}
