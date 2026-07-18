#include <stdint.h>                                              
#include <stdalign.h>                                            
                                                                 
// This file's content is created by the testvector generator    
// python script for seed = 2024.1                    
//                                                               
//  The variables are defined for the RSA                        
// encryption and decryption operations. And they are assigned   
// by the script for the generated testvector. Do not create a   
// new variable in this file.                                    
//                                                               
// When you are submitting your results, be careful to verify    
// the test vectors created for seeds from 2024.1, to 2024.5     
// To create them, run your script as:                           
//   $ python testvectors.py rsa 2024.1                          
                                                                 
// modulus                                                       
alignas(128) uint32_t N[32]       = {0x7072220b, 0x7523b631, 0xa7688b5c, 0x454036f3, 0x9002694f, 0xc8e76450, 0xf5304a34, 0x5628d426, 0x904372e0, 0xd994fdbd, 0x87b6b323, 0x5422bb18, 0x89f917fe, 0xd8ad1e2d, 0x69c376c1, 0x2367e735, 0x5056eebb, 0xa08b91c7, 0x2af8039e, 0xd589d77e, 0x100661c1, 0x1ed604bd, 0xce04b238, 0xfd5a6fe6, 0x3df4cb68, 0x644307b7, 0xffe04e9d, 0xc28e73ec, 0x90026da6, 0x5ab16689, 0x754bcdd8, 0x81d7004d};           
                                                                              
// encryption exponent                                                        
alignas(128) uint32_t e[32]       = {0x0000cc43};            
alignas(128) uint32_t e_len       = 16;                                       
                                                                              
// decryption exponent, reduced to p and q                                    
alignas(128) uint32_t d[32]       = {0x1ced4dd3, 0xefea8821, 0xcd72f4f7, 0x7d4eeb1c, 0x33a960bd, 0x20543cbe, 0xbd6a581a, 0x78929d2f, 0xe14759a5, 0x3295944b, 0xa6871068, 0x2d7f65f0, 0x1079b373, 0xac27cc10, 0x9834fc75, 0x6c84d959, 0x189f05ab, 0x58df9404, 0xd73d7128, 0x68303fc5, 0x514b3586, 0xee13fd92, 0xae648567, 0xe0c900fa, 0xd30026d0, 0x9fb02c92, 0x031ed245, 0xeaf487f0, 0xb73bfd27, 0x9c4c41d6, 0x1aace65d, 0x5036d042};           
alignas(128) uint32_t d_len       =  1023;    
                                                                              
// the message                                                                
alignas(128) uint32_t M[32]       = {0xe2f2c740, 0x5a2f485f, 0x127cd54b, 0x934fffd9, 0x957f5177, 0x0d90266d, 0x7a7b53e0, 0x2b6b8e52, 0xd445ce04, 0x3732f0d1, 0x1324c4d0, 0xc2b723e3, 0x296d9e37, 0x29b4d189, 0x6192cc58, 0x518a8cc3, 0x32cd190f, 0xe4cc96c2, 0x15417956, 0xcdb466a2, 0xef900571, 0xbe5cc145, 0x73c5a049, 0x3e40d836, 0x9fc235c9, 0x4bf5deb9, 0xac5ddaaa, 0x378ea342, 0x15c2c8d7, 0xad8ab408, 0x105c37c2, 0x80c58de7};           
                                                                              
// R mod N, and R^2 mod N, (R = 2^1024)                                       
alignas(128) uint32_t R_N[32]     = {0x8f8dddf5, 0x8adc49ce, 0x589774a3, 0xbabfc90c, 0x6ffd96b0, 0x37189baf, 0x0acfb5cb, 0xa9d72bd9, 0x6fbc8d1f, 0x266b0242, 0x78494cdc, 0xabdd44e7, 0x7606e801, 0x2752e1d2, 0x963c893e, 0xdc9818ca, 0xafa91144, 0x5f746e38, 0xd507fc61, 0x2a762881, 0xeff99e3e, 0xe129fb42, 0x31fb4dc7, 0x02a59019, 0xc20b3497, 0x9bbcf848, 0x001fb162, 0x3d718c13, 0x6ffd9259, 0xa54e9976, 0x8ab43227, 0x7e28ffb2};        
alignas(128) uint32_t R2_N[32]    = {0x3a44b63d, 0x610f40f2, 0xb8550e1c, 0xef8683ff, 0xde6b4ff0, 0xfccbdcda, 0xf448db72, 0x82f3aae2, 0x41939940, 0xdd8b8052, 0x087314df, 0xc5076580, 0xc44362f1, 0xf7cd10c4, 0x6e7d2ccd, 0x90e1205e, 0x5f8d1cec, 0x758217a3, 0x3b8916d3, 0x3e948317, 0x78fdbb27, 0x037c16da, 0x092b0327, 0x697c9f0c, 0x4ebe8fd7, 0x7d50bc8d, 0x91320335, 0x3f589c4c, 0xc32ec722, 0x3ff8d1c1, 0xc7145250, 0x592407dd};        
