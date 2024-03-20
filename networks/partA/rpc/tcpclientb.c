#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{
    int clientsock;
    struct sockaddr_in server_address;
    char buffer[1024];

    // Create a TCP socket
    clientsock = socket(AF_INET, SOCK_STREAM, 0);
    if (clientsock == -1)
    {
        perror("Error creating socket");
        exit(EXIT_FAILURE);
    }

    server_address.sin_family = AF_INET;
    server_address.sin_port = htons(12346);
    server_address.sin_addr.s_addr = inet_addr("127.0.0.1"); // Server IP address

    // Connect to the server
    if (connect(clientsock, (struct sockaddr *)&server_address, sizeof(server_address)) == -1)
    {
        perror("Error connecting to server");
        close(clientsock);
        exit(EXIT_FAILURE);
    }

    printf("Connected to server\n");
    while (1)
    {
        // Send data to the server
        printf("Client B, enter your choice: ");
        fgets(buffer, sizeof(buffer), stdin);
        buffer[strlen(buffer) - 1] = '\0';

        int sent_data = send(clientsock, buffer, strlen(buffer), 0);
        if (sent_data == -1)
        {
            perror("Error sending data");
            close(clientsock);
            exit(EXIT_FAILURE);
        }
        printf("Response sent to server\n");
        // Receive a response from the server
        int received_data = recv(clientsock, buffer, sizeof(buffer), 0);
        if (received_data == -1)
        {
            perror("Error receiving data");
            close(clientsock);
            exit(EXIT_FAILURE);
        }

        buffer[received_data] = '\0';
        printf("Received from server: %s\n", buffer);

        printf("Would you like to continue? ");
        fgets(buffer, sizeof(buffer), stdin);
        buffer[strlen(buffer) - 1] = '\0'; // Remove the newline character

        // Send data to the server
        sent_data = send(clientsock, buffer, strlen(buffer), 0);
        if (sent_data == -1)
        {
            perror("Error sending data");
            close(clientsock);
            exit(EXIT_FAILURE);
        }
        printf("Response sent to server\n");

        received_data = recv(clientsock, buffer, sizeof(buffer), 0);
        if (received_data == -1)
        {
            perror("Error receiving data");
            close(clientsock);
            exit(EXIT_FAILURE);
        }

        buffer[received_data] = '\0';
        if (strcmp(buffer, "End") == 0)
            exit(1);

        sleep(2);
    }
    // Close the socket
    close(clientsock);

    return 0;
}
