#include<stdio.h>
#include<stdlib.h>
#include<math.h>

#define N 10 /// order of the filter
#define NT (N+1) /// number of coeffs
#define NB 14 /// number of bits
#define SHAMT 19 /// shift amount

//THIS FILTER IMPLEMENTS A RATIONAL TRANSFER FUNCTION, WHERE bi ARE THE MOVING AVERAGE COEFFICIENTS (AS IN A SIMPLE FIR FILTER), WHERE ai ARE THE AUTO-REGRESSIVE COEFFICIENTS (IIR ONLY)

// # OF b COEFFICIENTS ARE # of a GRADE + 1

const int bi[NT]={ -1, - 104, - 203,	520,	2251,	3260,	2251,	520, - 203, - 104, - 1 }; /// b array

/// Perform fixed point filtering assuming direct form I
///\param x is the new input sample
///\return the new output sample
///

int myfilter(int x)
{
  static int sx[NT]; /// x shift register
  static int sy[NT-1]; /// y shift register
  static int first_run = 0; /// for cleaning shift registers
  int i; /// index
  int y; /// output sample

  /// clean the buffers
  if (first_run == 0)
  {
    first_run = 1;
    for (i=0; i<NT; i++)
      sx[i] = 0;
    for (i=0; i<NT-1; i++)
      sy[i] = 0;
  }

  /// shift and insert new sample in x shift register
  for (i=NT-1; i>0; i--)
    sx[i] = sx[i-1];
  sx[0] = x;

  /// make the convolution
  /// Moving average part
  y = 0;
  for (i=0; i<NT; i++)
  {
      y += ((sx[i]*bi[i]) >> SHAMT) << (SHAMT - NB + 1);
      printf("y_part: %d, prod: %d, sx: %d, b: %d\n", ((sx[i]*bi[i]) >> SHAMT) << (SHAMT), (sx[i]*bi[i]), sx[i], bi[i]);
  }


  /// update the y shift register
  for (i=NT-2; i>0; i--)
    sy[i] = sy[i-1];
  sy[0] = y;

  return y;
}

int main (int argc, char **argv)
{
  FILE *fp_in;
  FILE *fp_out;

  int x;
  int y;

  /// check the command line
  if (argc != 3)
  {
    printf("Use: %s <input_file> <output_file>\n", argv[0]);
    exit(1);
  }
  
  /// open files
  fp_in = fopen(argv[1], "r");
  if (fp_in == NULL)
  {
    printf("Error: cannot open %s\n");
    exit(2);
  }
  fp_out = fopen(argv[2], "w");

  /// check shift amount
  if (SHAMT < ((NB)-1))
  {
    printf("Error shift amount must be at least nbit-1\n");
    exit(3);
  }

  /// get samples and apply filter
  fscanf(fp_in, "%d", &x);
  do{
    y = myfilter(x);
    fprintf(fp_out,"%d\n", y);
    fscanf(fp_in, "%d", &x);

  } while (!feof(fp_in));

  fclose(fp_in);
  fclose(fp_out);

  return 0;

}
