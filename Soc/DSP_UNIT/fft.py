import random
import math 
import numpy as np

#256 rows & 9 columns
dft_matrix_r = np.zeros((9,256))
dft_matrix_i = np.zeros((9,256))


x_samples = [0]*256;
r_LUT     = [0]*256;
i_LUT     = [0]*256;
r_MEM     = [0]*256;
i_MEM     = [0]*256;
r4_MEM    = [0]*256;


#LUT roots of unity(cos - R)
for i in range(256):
    r_LUT[i] = math.cos(2*math.pi*(i/256))

for i in range(256):
    i_LUT[i] = math.sin(2*math.pi*(i/256))

for i in range(256):
    x_samples[i] = random.randint(-50,50)


#0 is sample
for i in range(256):
    dft_matrix_r[0][i] = random.randint(-50,50)







#special shifter (l_s)
dft_p = 2
l_s = 2; 
r_s = 128
e_pivot = 0 
k       = 0 #kth bin..
addr = 0

#stage 1 works
#iterating through the k's
while (k < (l_s >> 1)):
    #1 get even and odd values
        #print('addr: ', addr, 'odd:', (e_pivot + r_s + k - (dft_p/2)))
    even = x_samples[e_pivot*(dft_p>>1) + k]
    odd =  x_samples[e_pivot*(dft_p >> 1) + k + r_s]

    #2 calculate both possibilites 
    s1   = even +  r_LUT[k*r_s]*odd
    s2   = even -  r_LUT[(k*r_s)]*odd


    #4 store in MEM(2 writes)
    r_MEM[e_pivot*dft_p + k] = s1
    r_MEM[e_pivot*dft_p + k + (l_s >> 1)] = s2

    #print("e_pivot:", e_pivot, "kth: ", k)
    if(e_pivot != ((r_s)-1)):
        e_pivot = e_pivot + 1
    else:
        e_pivot = 0
        k = k + 1

# for i, val in enumerate(r_MEM):
#      print(f"{i:3d}: {val}")


r_s = r_s >> 1
l_s = l_s << 1
dft_p = dft_p << 1
k = 0
e_pivot = 0
addr = 0

#4 point DFT
#sake of simplicity
dft_p = 2
l_s = 2; 
r_s = 128
e_pivot = 0 
k       = 0 #kth bin..
while (k < (l_s >> 1)):
    #1 get even and odd values
        #print('addr: ', addr, 'odd:', (e_pivot + r_s + k - (dft_p/2)))
    even = r_MEM[e_pivot*(dft_p>>1) + k]
    odd =  r_MEM[e_pivot*(dft_p >> 1) + k + 128]

    #2 calculate both possibilites 
    s1   = even +  r_LUT[k*r_s]*odd
    s2   = even -  r_LUT[(k*r_s)]*odd


    #4 store in MEM(2 writes)
    r4_MEM[e_pivot*dft_p + k] = s1
    r4_MEM[e_pivot*dft_p + k + (l_s >> 1)] = s2


    #print("e_pivot:", e_pivot, "kth: ", k)
    if(e_pivot != ((r_s)-1)):
        e_pivot = e_pivot + 1
    else:
        e_pivot = 0
        k = k + 1

# for i, val in enumerate(r4_MEM):
#      print(f"{i:3d}: {val}")




#special shifter (l_s)
dft_p = 2
l_s = 2; 
r_s = 128
e_pivot = 0 
k       = 0 #kth bin..
addr = 0



for x in range(8):


    while (k < (l_s >> 1)):
        #1 get even and odd values
        #print('addr: ', addr, 'odd:', (e_pivot + r_s + k - (dft_p/2)))
        even_r = dft_matrix_r[x][e_pivot*(dft_p>>1) + k]
        odd_r  = dft_matrix_r[x][e_pivot*(dft_p >> 1) + k + 128]

        even_i = dft_matrix_i[x][e_pivot*(dft_p>>1) + k]
        odd_i  = dft_matrix_i[x][e_pivot*(dft_p>>1) + k+128]




        #2 calculate both possibilites 
        s1_r   = even_r +  (r_LUT[k*r_s]*odd_r - i_LUT[k*r_s]*odd_i)
        s1_i   = even_i +  (i_LUT[k*r_s]*odd_r + r_LUT[k*r_s]*odd_i)
        s2_r   = even_r -  (r_LUT[k*r_s]*odd_r - i_LUT[k*r_s]*odd_i)
        s2_i   = even_i -  (i_LUT[k*r_s]*odd_r + r_LUT[k*r_s]*odd_i)



        #4 store in MEM(2 writes)
        dft_matrix_r[x+1][e_pivot*dft_p + k] = s1_r
        dft_matrix_r[x+1][e_pivot*dft_p + k + (l_s >> 1)] = s2_r

        dft_matrix_i[x+1][e_pivot*dft_p + k] = s1_i
        dft_matrix_i[x+1][e_pivot*dft_p + k + (l_s >> 1)] = s2_i



        #print("e_pivot:", e_pivot, "kth: ", k)
        if(e_pivot != ((r_s)-1)):
            e_pivot = e_pivot + 1
        else:
            e_pivot = 0
            k = k + 1
    


    k = 0
    e_pivot = 0
    x = x + 1
    r_s = r_s >> 1
    l_s = l_s << 1
    dft_p = dft_p << 1

print("First row:")
print(dft_matrix_r[0])

print("\nLast row:")
print(dft_matrix_r[-1])