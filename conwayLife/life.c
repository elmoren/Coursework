/***************************************
	Conway's Game of Life, 3D
 ***************************************/

/**
 * Author: Nathan Elmore
 * Started: 4/18/2011
 */

/**
 * Basic 2d Rules
 *
 * The universe of the Game of Life is an infinite two-dimensional orthogonal 
 * grid of square cells, each of which is in one of two possible states, live or dead.
 * Every cell interacts with its eight neighbours, which are the cells that are 
 * horizontally, vertically, or diagonally adjacent. At each step in time, the following transitions 
 * occur:
 *
 * Any live cell with fewer than two live neighbours dies, as if caused by under-population.
 * Any live cell with two or three live neighbours lives on to the next generation.
 * Any live cell with more than three live neighbours dies, as if by overcrowding.
 * Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
 */

/**
 * 3D Rules
 *
 *
 * This is a 3D version with the same basic rules, except that a cell has 26 possible neighbors
 * instead of 8.
 *
 * The 3D version has the 4 basic rules, except that they are fully customizable when running the
 * program from the command line. If no arguments are given, it uses the basic 2D rules on a 3D grid.
 */
 
/**
 * Includes and definitions
 */

#ifdef __APPLE__
#include <GLUT/glut.h>
#else
#include <GL/glut.h>
#endif

#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#define LENGTH 50
#define WIDTH  50
#define HEIGHT 50

/**
 * Globals
 */

/* 2 Grids, display and temp. */
GLint grid[LENGTH][WIDTH][HEIGHT];
GLint temp[LENGTH][WIDTH][HEIGHT];

/* Transformation variables */
GLfloat xRot = -45.0;
GLfloat yRot = 45.0;

/* Basic Rules, can be overridden by command line args */
int minNeighbors = 2; // minimun number of neighbors to live
int maxNeighbors = 3; // maximum number of neighbors to live
int alive = 3;        // number of neighbors for dead cell to live
float density = 0.002;// Seems to work better with a low initial density

/* Flags */
int counting = 0;
int autoUpdate = 0;

/**
 * Program Logic Methods
 */

/**
 * Function: counts live cells
 */
void countLive()
{
	int alive = 0;
	int i,j,k;
	
	for (i = 0; i < LENGTH; i++)
		for (j = 0; j < WIDTH; j++)
			for (k = 0; k < HEIGHT; k++)
				if(grid[i][j][k]) alive++;
	
	printf("there are %d alive\n", alive);
}

/**
 * Function: Initial set up of grid based on density. Float Values 0.0-1.0
 *
 * density of 0.2 would mean that approx. 20% of cells are initially
 * alive
 */
void seed(float density)
{
	int i, j, k;
	float randomFloat;
	
	// check input...
	density = (density > 1.0) ? 1.0 : density;
	density = (density < 0.0) ? 0.0 : density;
	
	// seed random
	srand((unsigned)(time(0)));
	
	for (i = 0; i < LENGTH; i++)
		for (j = 0; j < WIDTH; j++)
			for (k = 0; k < HEIGHT; k++)
			{
				randomFloat = rand()/((float)(RAND_MAX)+1); 
				if (randomFloat < density) 
				{
					grid[i][j][k] = 1;
				}
				else 
				{
					grid[i][j][k] = 0;
				}
			}
	
}

/**
 * Function: returns the number of alive neighbors for a given cell
 */
int countNeighbors(int l, int w, int h)
{
	int count = 0;
	int i, j, k;
	
	for (i = (l - 1); i <= (l + 1); i++)
		for (j = (w - 1); j <= (w + 1); j++)
			for (k = (h - 1); k <= (h + 1); k++) 
			{
				// If its out of bounds, continue...
				if(i < 0 || i >= LENGTH ||
				   j < 0 || j >= WIDTH  ||
				   k < 0 || k >= HEIGHT ) 
				{
					continue;
				}
				// check if its alive
				else 
				{
					// make sure its not the active cell
					if(i == l && j == w && k == h)
						continue;
					else 
						if(grid[i][j][k]>0) count++;
				}
				
			}
	
	return count;
}

/**
 * Ages the grid by 'count' cycles. Loops though every cell, countsNeighbors, and updates
 */
void age()
{	
	int i,j,k;
	int neighbors = 0;
	// Loop through every cell and put new values in temp grid.
	for (i = 0; i < LENGTH; i++)
		for (j = 0; j < WIDTH; j++)
			for (k = 0; k < HEIGHT; k++) 
			{
				neighbors = countNeighbors(i, j, k);
				if (neighbors < minNeighbors || neighbors > maxNeighbors)
				{
					temp[i][j][k] = 0; // dies
				}
				else if (neighbors == alive && grid[i][j][k] == 0) 
				{
					// its its dead and has right number of neighbors, cell is born
					temp[i][j][k] = 1;
				}
				else 
				{
					//if it doesn't die it gets older
					temp[i][j][k] = grid[i][j][k] + 15;
				}
			}
	
	// then copy temp to grid... inefficient, should have used pointers
	for (i = 0; i < LENGTH; i++)
		for (j = 0; j < WIDTH; j++)
			for (k = 0; k < HEIGHT; k++) 
				grid[i][j][k] = temp[i][j][k];
}

/**
 * Function: Uses timer callback to run while autoUpdate is true
 */
void autoAge(int i) 
{
	age();
	if(autoUpdate) 
	{
		glutTimerFunc(500, autoAge, i);
	}
	glutPostRedisplay();
}

/**
 * Function: Prints usage
 */
void printCommands() 
{
	printf("'F2' Re-seeds the matrix using the given rules\n");
	printf("Space ages the model 1 generation\n");
	printf("'c' toggles displaying number of live cells\n");
	printf("'h' prints this help\n");
	printf("Arrow keys will rotate the model\n");
	printf("'r' starts the auto-age function and the model will age every half second\n");
	printf("'e' stops the auto-age function\n");
	printf("'q' quits the program\n");
}

/**
 * Graphical Functions
 */

/**
 * Function: sets color based on how long the cell has been alive
 */
void setColor(int c)
{
	if(c >= 255)
	{
		c = 255;
	}
	glColor3f(c/255, 1.0 - c/255, 0.0);
}

/**
 * Function: Basic Display Callback Function
 */
void display()
{
	int i,j,k;
	int cell;
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glLoadIdentity();
	glRotatef(xRot, 1.0, 0.0, 0.0);
	glRotatef(yRot, 0.0, 1.0, 0.0);
	glTranslatef(-0.5, -0.5, -0.5);
	glBegin(GL_POINTS);
	
	for (i = 0; i < LENGTH; i++)
		for (j = 0; j < WIDTH; j++)
			for (k = 0; k < HEIGHT; k++)
			{
				cell = grid[i][j][k];
				if(cell)
				{
					setColor(cell);
					glVertex3f((float)i/LENGTH,(float)j/WIDTH,(float)k/HEIGHT);
				}
			}
	glEnd();
	
	if(counting)
		countLive();
	
	glFlush();
	// Double Buffering
	glutSwapBuffers();
}

/**
 * Function: Keyboard commands
 */
void keyboard(unsigned char key, int x, int y)
{
	switch (key) {
		case 'q':
			exit(0);
			break;
		case ' ':
			age();
			break;
		case 'c':
			counting = !counting;
			break;
		case 'r' :
			autoUpdate = 1;
			autoAge(1);
			break;
		case 'e' :
			autoUpdate = 0;
			break;
		case 'h':
			printCommands();
			return;
		default:
			break;
	}
	
	glutPostRedisplay();
}

/**
 * Function: Special keys commands
 */
void specialKeys(int key, int x, int y)
{
	switch (key) {
		case GLUT_KEY_UP:
			xRot += 2.5;
			break;
		case GLUT_KEY_DOWN:
			xRot -= 2.5;
			break;
		case GLUT_KEY_LEFT:
			yRot += 2.5;
			break;
		case GLUT_KEY_RIGHT:
			yRot -= 2.5;
			break;
		case GLUT_KEY_F2:
			seed(density);
			break;
		default:
			break;
	}
	glutPostRedisplay();
}

/**
 * Function: init
 */
void myInit()
{
	// attributes                                                                 
	glClearColor(0.0,0.0,0.0,0.0);
	glPointSize(2.5);
	// standard viewing                                                           
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(-1.2, 1.2, -1.2, 1.2, -1.2, 1.2);
	glMatrixMode(GL_MODELVIEW);
	
}

/**
 * Main Method
 */

int main (int argc, char* argv[]) 
{	
	// Print Instructions
	printf("Command Line args:: <density: 0.0-1.0> <Min Neighbors> <Max Neighbors> <Number to be born> \n");
	printf("\n");
	printCommands();
	
	// Process arguments
	if (argc == 5) 
	{
		density      = atof(argv[1]);
		density      = (density > 1.0) ? 1.0 : density;
		density      = (density < 0.0) ? 0.0 : density;
		minNeighbors = atoi(argv[2]);
		minNeighbors = (minNeighbors < 0) ? 0 : minNeighbors;
		maxNeighbors = atoi(argv[3]);
		maxNeighbors = (maxNeighbors > 26) ? 26 : maxNeighbors;
		alive        = atoi(argv[4]);
		alive        = (alive < 0) ? 0 : alive;
		alive		 = (alive > 26) ? 26 : alive;
	}
	
    // Initialize GLUT, Windows, etc	
	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);       
	glutInitWindowSize (750, 750);
	glutInitWindowPosition (25, 25);
	glutCreateWindow("Game of Life: 3D");
	glEnable(GL_DEPTH_TEST);
	
	// CALLBACK FUNCTIONS
	glutDisplayFunc(display);
	glutKeyboardFunc(keyboard);
	glutSpecialFunc(specialKeys);

	// Other OpenGl Settings
	myInit();
	//glOrtho(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0);
	
	// Randomlay initialize the grid based on density
	seed(density);
	
	glutMainLoop();

	return 0;
}
