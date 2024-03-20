import matplotlib.pyplot as plt

'''
    1: [961, 968, 995, 1053],
    2: [961, 963, 999, 1063],
    3: [970, 973, 1007, 1083],
    4: [971, 983, 1027, 1133],
    5: [971, 987, 1035, 1153]
'''

processes = {
    
    1: [3940, 3942, 3954, 3980],
    2: [3940, 3944, 3958, 3990],
    3: [3940, 3946, 3962, 4000],
    4: [3940, 3948, 3966, 4010],
    5: [3940, 3950, 3970, 4020]
}


color_map = {
    1: 'chocolate',
    2: 'gold',
    3: 'chartreuse',
    4: 'cyan',
    5: 'violet'
}

fig, ax = plt.subplots()


end_time = max(max(ticks) for ticks in processes.values())

# Loop through each process
for id, ticks in processes.items():
    x = []  # Time ticks
    y = []  # Queue ID
    
    for i, tick in enumerate(ticks):
        x.extend([tick, tick])  
        y.extend([i + 1, i + 1]) #Maintain queue ID for horizontal lines
        
        #vertical lines
        if i < len(ticks) - 1:
            x.append(ticks[i + 1])
            y.append(i + 1)
            x.append(ticks[i + 1])
            y.append(i + 2)
    
    # horizontal line for queue 4
    x.extend([ticks[-1], ticks[-1], end_time]) 
    y.extend([len(ticks) + 1,len(ticks) + 1, len(ticks) + 1])
    
    #horizontal lines
    ax.plot(x, y, marker='', linestyle='-', label=f'Process {id}', color=color_map[id])

#
ax.set_xlabel('Time Elapsed from Start (in ticks)')
ax.set_ylabel('Queue ID')
ax.set_title('Timeline Plot for Processes')


ax.set_yticks(range(1, len(processes) + 2))


ax.legend()


ax.grid()
plt.show()
