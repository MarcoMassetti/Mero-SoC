#define N 7
#define myabs(x) (((x) < 0) ? (-(x)) : (x))

int v[N] = {9, -46, 21, -2, 14, 26, -3};
volatile int m;

int minv(int *v, int num)
{
  int i;
  int m;

  m = myabs(v[0]);
  for (i=1; i<N; i++)
  {
    if (m > myabs(v[i]))
      m = myabs(v[i]);
  }
  
  return m;
}



int main()
{

  m = minv(v, N);

#ifdef IS86
  printf("%d\n", m);
#endif
  return 0;
}
