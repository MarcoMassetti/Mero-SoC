
#define myabs(x) (((x) < 0) ? (-(x)) : (x))

int minv(int *v, int N)
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


int v[7] = {9, -46, 21, -2, 14, 26, -3};
volatile int m;


int main()
{	
	
	m = minv(v, 7);


	return 0;
}
