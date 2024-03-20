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

    // Create a UDP socket
    clientsock = socket(AF_INET, SOCK_DGRAM, 0);
    if (clientsock == -1)
    {
        perror("Error creating socket");
        exit(EXIT_FAILURE);
    }

    server_address.sin_family = AF_INET;
    server_address.sin_port = htons(12346);
    server_address.sin_addr.s_addr = inet_addr("127.0.0.1"); // Server IP address

    while (1)
    {
        // Send data to the server
        printf("Client B, enter your choice: ");
        fgets(buffer, sizeof(buffer), stdin);
        buffer[strlen(buffer) - 1] = '\0'; // Remove the newline character

        // Send data to the server
        int sent_data = sendto(clientsock, buffer, strlen(buffer), 0, (struct sockaddr *)&server_address, sizeof(server_address));
        if (sent_data == -1)
        {
            perror("Error sending data");
            close(clientsock);
            exit(EXIT_FAILURE);
        }
        printf("Response sent to server\n");
        // Receive a response from the server
        int received_data = recvfrom(clientsock, buffer, sizeof(buffer), 0, NULL, NULL);
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
         sent_data = sendto(clientsock, buffer, strlen(buffer), 0, (struct sockaddr *)&server_address, sizeof(server_address));
        if (sent_data == -1)
        {
            perror("Error sending data");
            close(clientsock);
            exit(EXIT_FAILURE);
        }
        printf("Response sent to server\n");
        
        received_data = recvfrom(clientsock, buffer, sizeof(buffer), 0, NULL, NULL);
        if (received_data == -1)
        {
            perror("Error receiving data");
            close(clientsock);
            exit(EXIT_FAILURE);
        }

        buffer[received_data] = '\0';
        if(strcmp(buffer,"End")==0)
        {
            printf("Game over\n");
            exit(1);
        }

       // sleep(2); // Sleep for a while before sending the next message
    }

    // The client should never reach this point
    close(clientsock);

    return 0;
}
