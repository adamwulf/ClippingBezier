//
//  NearestPoint.c
//  ClippingBezier
//
//  Created by Adam Wulf on 5/9/15.
//
//

#include "NearestPoint.h"

/*
 Solving the Nearest Point-on-Curve Problem
 and
 A Bezier Curve-Based Root-Finder
 by Philip J. Schneider
 from "Graphics Gems", Academic Press, 1990
 */

/*	point_on_curve.c	*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define TESTMODE

/**
 * originally from GGVecLib.c from Graphics Gems.
 * used to take pointers to vectors,
 * modified to take CGPoint
 *
 * return vector difference c = a-b
 Vector2 *V2Sub(a, b, c)
 Vector2 *a, *b, *c;
 {
 c->x = a->x-b->x;  c->y = a->y-b->y;
 return(c);
 }
 */
CGPoint CGPointDiff(CGPoint a, CGPoint b){
    return CGPointMake(a.x - b.x, a.y - b.y);
}

/**
 * originally from GGVecLib.c from Graphics Gems.
 * modified to take CGPoint
 *
 *
 * returns squared length of input vector
double V2SquaredLength(a)
Vector2 *a;
{	return((a->x * a->x)+(a->y * a->y));
}
*/
double V2SquaredLength(CGPoint a){
    return((a.x * a.x)+(a.y * a.y));
}

/**
 * originally from GGVecLib.c form Graphics Gems.
 * modified to take CGPoint
 *
 *
 * return the dot product of vectors a and b
double V2Dot(a, b)
Vector2 *a, *b;
{
    return((a->x*b->x)+(a->y*b->y));
}
*/
double V2Dot(CGPoint a, CGPoint b){
    return((a.x * b.x)+(a.y * b.y));
}

/** begin NearestPoint.c **/

#if !defined(MIN)
#define MIN(A,B) (A<B ? A : B)
#endif

#if !defined(MAX)
#define MAX(A,B) (A>B ? A : B)
#endif

#if !defined(SGN)
#define SGN(a)		(((a)<0) ? -1 : 0)
#endif

/*
 *  Forward declarations
 */
static CGPoint*		ConvertToBezierForm( const CGPoint inp, const CGPoint bez[4] );
CGPoint Bezier(const CGPoint* V, const int degree, const double t, CGPoint* Left, CGPoint* Right);
static int CrossingCount(CGPoint* V, int degree);
static int ControlPolygonFlatEnough(CGPoint* V, int degree);
static double ComputeXIntercept(CGPoint* V, int degree);
static	CGPoint	V2ScaleII(CGPoint v, double s);

int		MAXDEPTH = 64;	/*  Maximum depth for recursion */

#define	EPSILON	(ldexp(1.0,-MAXDEPTH-1)) /*Flatness control value */
#define	DEGREE	3			/*  Cubic Bezier curve		*/
#define	W_DEGREE 5			/*  Degree of eqn to find roots of */


/*
 *  NearestPointOnCurve :
 *  	Compute the parameter value of the point on a Bezier
 *		curve segment closest to some arbtitrary, user-input point.
 *		Return the point on the curve at that parameter value.
 * CGPoint 	P; //The user-supplied point
 * CGPoint 	*V; //Control points of cubic Bezier
 *
 */
CGPoint		NearestPointOnCurve( const CGPoint inp, const CGPoint bez[4], double* tValue )
{
    CGPoint*	w;						// Ctl pts for 5th-degree eqn
    double		t_candidate[5];			// Possible roots
    int			n_solutions;			// Number of roots found
    double		t;						// Parameter value of closest pt
    
    // Convert problem to 5th-degree Bezier form
    
    w = ConvertToBezierForm( inp, bez );
    
    // Find all possible roots of 5th-degree equation
    
    n_solutions = FindRoots( w, 5, t_candidate, 0 );
    free((char*) w);
    
    // Compare distances of P to all candidates, and to t=0, and t=1
    
    double		dist, new_dist;
    CGPoint 	p;
    int			i;
    
    // Check distance to beginning of curve, where t = 0
    
    dist = V2SquaredLength(CGPointDiff( inp, bez[0] ));
    t = 0.0;
    
    // Find distances for candidate points
    
    for (i = 0; i < n_solutions; i++)
    {
        p = Bezier( bez, DEGREE, t_candidate[i], NULL, NULL );
        
        new_dist = V2SquaredLength(CGPointDiff( inp, p ));
        if ( new_dist < dist )
        {
            dist = new_dist;
            t = t_candidate[i];
        }
    }
    
    // Finally, look at distance to end point, where t = 1.0
    
    new_dist = V2SquaredLength(CGPointDiff( inp, bez[3]));
    if (new_dist < dist)
    {
        t = 1.0;
    }
    
    /*  Return the point on the curve at parameter value t */
//    LogEvent_(kInfoEvent, @"t : %4.12f", t);
    
    if ( tValue )
        *tValue = t;
    
    return Bezier( bez, DEGREE, t, NULL, NULL);
}


/*
 *  ConvertToBezierForm :
 *		Given a point and a Bezier curve, generate a 5th-degree
 *		Bezier-format equation whose solution finds the point on the
 *      curve nearest the user-defined point.
 * CGPoint 	P;			The point to find t for
 * CGPoint 	*V;			The control points
 */
static CGPoint*		ConvertToBezierForm( const CGPoint inp, const CGPoint bez[4] )
{
    int				i, j, k, m, n, ub, lb;
    int				row, column;		// Table indices
    CGPoint			c[DEGREE+1];				// V(i)'s - P
    CGPoint			d[DEGREE];				// V(i+1) - V(i)
    CGPoint*		w;					// Ctl pts of 5th-degree curve
    double			cdTable[3][4];		// Dot product of c, d
    
    static double z[3][4] = {	/* Precomputed "z" for cubics	*/
        {1.0, 0.6, 0.3, 0.1},
        {0.4, 0.6, 0.6, 0.4},
        {0.1, 0.3, 0.6, 1.0},
    };
    
    
    /*Determine the c's -- these are vectors created by subtracting*/
    /* point P from each of the control points				*/
    for (i = 0; i <= DEGREE; i++)
    {
        c[i] = CGPointDiff( bez[i], inp );
    }
    
    /* Determine the d's -- these are vectors created by subtracting*/
    /* each control point from the next					*/
    for (i = 0; i < DEGREE; i++)
    {
        d[i] = CGPointDiff(bez[i+1], bez[i]);
        d[i] = V2ScaleII(d[i], 3.0);
    }
    
    /* Create the c,d table -- this is a table of dot products of the */
    /* c's and d's							*/
    
    for (row = 0; row <= DEGREE - 1; row++) {
        for (column = 0; column <= DEGREE; column++) {
            cdTable[row][column] = V2Dot( d[row], c[column] );
        }
    }
    
    /* Now, apply the z's to the dot products, on the skew diagonal*/
    /* Also, set up the x-values, making these "points"		*/
    
    w = (CGPoint*)	malloc((W_DEGREE+1) * sizeof(CGPoint));
    for (i = 0; i <= W_DEGREE; i++)
    {
        w[i].y = 0.0;
        w[i].x = (double)(i) / W_DEGREE;
    }
    
    n = DEGREE;
    m = DEGREE-1;
    
    for (k = 0; k <= n + m; k++)
    {
        lb = MAX(0, k - m);
        ub = MIN(k, n);
        
        for (i = lb; i <= ub; i++)
        {
            j = k - i;
            w[i+j].y += cdTable[j][i] * z[j][i];
        }
    }
    
    return w;
}


/*
 *  FindRoots :
 *	Given a 5th-degree equation in Bernstein-Bezier form, find
 *	all of the roots in the interval [0, 1].  Return the number
 *	of roots found.
 * CGPoint 	*w;			The control points
 * int 	degree;         The degree of the polynomial
 * double 	*t;			RETURN candidate t-values
 * int 	depth;          The depth of the recursion
 */
int FindRoots( CGPoint* w, int degree, double* t, int depth )
{
    int			i;
    CGPoint 	Left[W_DEGREE+1], Right[W_DEGREE+1];	// control polygons
    int			left_count,	 right_count;
    double		left_t[W_DEGREE+1], right_t[W_DEGREE+1];
    
    switch ( CrossingCount( w, degree ))
    {
       	default:
            break;
            
        case 0:	// No solutions here
            return 0;
            
        case 1:	// Unique solution
            // Stop recursion when the tree is deep enough
            // if deep enough, return 1 solution at midpoint
            
            if (depth >= MAXDEPTH)
            {
                t[0] = ( w[0].x + w[W_DEGREE].x) / 2.0;
                return 1;
            }
            
            if ( ControlPolygonFlatEnough( w, degree ))
            {
                t[0] = ComputeXIntercept( w, degree );
                return 1;
            }
            break;
    }
    
    // Otherwise, solve recursively after
    // subdividing control polygon
    
    Bezier( w, degree, 0.5, Left, Right );
    left_count  = FindRoots( Left,  degree, left_t, depth+1 );
    right_count = FindRoots( Right, degree, right_t, depth+1 );
    
    // Gather solutions together
    for (i = 0; i < left_count; i++)
    {
        t[i] = left_t[i];
    }
    for (i = 0; i < right_count; i++)
    {
        t[i+left_count] = right_t[i];
    }
    
    // Send back total number of solutions
    
    return (left_count + right_count);
}


/*
 * CrossingCount :
 *	Count the number of times a Bezier control polygon
 *	crosses the 0-axis. This number is >= the number of roots.
 *
 * Point2	*V;			Control pts of Bezier curve
 * int		degree;		Degreee of Bezier curve
 */
static int CrossingCount( CGPoint* v, int degree )
{
    int 	i;
    int 	n_crossings = 0;	/*  Number of zero-crossings	*/
    int		sign, old_sign;		/*  Sign of coefficients	*/
    
    old_sign = SGN( v[0].y );
    
    for ( i = 1; i <= degree; i++ )
    {
        sign = SGN( v[i].y );
        
        if (sign != old_sign)
            n_crossings++;
        old_sign = sign;
    }
    return n_crossings;
}



/*
 *  ControlPolygonFlatEnough :
 *	Check if the control polygon of a Bezier curve is flat enough
 *	for recursive subdivision to bottom out.
 *
 */
static int ControlPolygonFlatEnough( CGPoint* v, int degree )
{
    int			i;					// Index variable
    double*		distance;			// Distances from pts to line
    double		max_distance_above;	// maximum of these
    double		max_distance_below;
    double		error;				// Precision of root
    double		intercept_1,
				intercept_2,
				left_intercept,
				right_intercept;
    double		a, b, c;			// Coefficients of implicit
    // eqn for line from V[0]-V[deg]
    
    /* Find the  perpendicular distance		*/
    /* from each interior control point to 	*/
    /* line connecting V[0] and V[degree]	*/
    distance = (double*) malloc((unsigned)(degree + 1) * sizeof(double));
    {
        double	abSquared;
        
        /* Derive the implicit equation for line connecting first */
        /*  and last control points */
        a = v[0].y - v[degree].y;
        b = v[degree].x - v[0].x;
        c = v[0].x * v[degree].y - v[degree].x * v[0].y;
        
        abSquared = (a * a) + (b * b);
        
        for (i = 1; i < degree; i++)
        {
            // Compute distance from each of the points to that line
            distance[i] = a * v[i].x + b * v[i].y + c;
            if (distance[i] > 0.0)
            {
                distance[i] = (distance[i] * distance[i]) / abSquared;
            }
            if (distance[i] < 0.0)
            {
                distance[i] = -((distance[i] * distance[i]) / abSquared);
            }
        }
    }
    
    /* Find the largest distance	*/
    max_distance_above = 0.0;
    max_distance_below = 0.0;
    for (i = 1; i < degree; i++)
    {
        if (distance[i] < 0.0)
        {
            max_distance_below = MIN(max_distance_below, distance[i]);
        }
        if (distance[i] > 0.0)
        {
            max_distance_above = MAX(max_distance_above, distance[i]);
        }
    }
    free((char *)distance);
    
    {
        double	det, dInv;
        double	a1, b1, c1, a2, b2, c2;
        
        /*  Implicit equation for zero line */
        a1 = 0.0;
        b1 = 1.0;
        c1 = 0.0;
        
        /*  Implicit equation for "above" line */
        a2 = a;
        b2 = b;
        c2 = c + max_distance_above;
        
        det = a1 * b2 - a2 * b1;
        dInv = 1.0/det;
        
        intercept_1 = (b1 * c2 - b2 * c1) * dInv;
        
        /*  Implicit equation for "below" line */
        a2 = a;
        b2 = b;
        c2 = c + max_distance_below;
        
        det = a1 * b2 - a2 * b1;
        dInv = 1.0/det;
        
        intercept_2 = (b1 * c2 - b2 * c1) * dInv;
    }
    
    /* Compute intercepts of bounding box	*/
    left_intercept = MIN(intercept_1, intercept_2);
    right_intercept = MAX(intercept_1, intercept_2);
    
    error = 0.5 * (right_intercept - left_intercept);    
    if (error < EPSILON)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}



/*
 *  ComputeXIntercept :
 *	Compute intersection of chord from first control point to last
 *  	with 0-axis.
 *
 */
/* NOTE: "T" and "Y" do not have to be computed, and there are many useless
 * operations in the following (e.g. "0.0 - 0.0").
 */
static double ComputeXIntercept( CGPoint* v, int degree)
{
    double	XLK, YLK, XNM, YNM, XMK, YMK;
    double	det, detInv;
    double	S;
    double	X;
    
    XLK = 1.0;
    YLK = 0.0;
    XNM = v[degree].x - v[0].x;
    YNM = v[degree].y - v[0].y;
    XMK = v[0].x;
    YMK = v[0].y;
    
    det = XNM*YLK - YNM*XLK;
    detInv = 1.0/det;
    
    S = (XNM*YMK - YNM*XMK) * detInv;
    X = XLK * S;
    
    return X;
}


/*
 *  Bezier :
 *	Evaluate a Bezier curve at a particular parameter value
 *      Fill in control points for resulting sub-curves if "Left" and
 *	"Right" are non-null.
 *
static CGPoint Bezier(V, degree, t, Left, Right)
int 	degree;		// Degree of bezier curve
CGPoint 	*V;			// Control pts
double 	t;			// Parameter value
CGPoint 	*Left;		// RETURN left half ctl pts
CGPoint 	*Right;		// RETURN right half ctl pts
*/
CGPoint		Bezier( const CGPoint* v, const int degree, const double t, CGPoint* Left, CGPoint* Right )
{
    int 	i, j;		/* Index variables	*/
    CGPoint 	Vtemp[W_DEGREE+1][W_DEGREE+1];
    
    
    /* Copy control points	*/
    for (j =0; j <= degree; j++)
    {
        Vtemp[0][j] = v[j];
    }
    
    /* Triangle computation	*/
    for (i = 1; i <= degree; i++)
    {
        for (j =0 ; j <= degree - i; j++)
        {
            Vtemp[i][j].x = (1.0 - t) * Vtemp[i-1][j].x + t * Vtemp[i-1][j+1].x;
            Vtemp[i][j].y = (1.0 - t) * Vtemp[i-1][j].y + t * Vtemp[i-1][j+1].y;
        }
    }
    
    if ( Left )
    {
        for (j = 0; j <= degree; j++)
        {
            Left[j]  = Vtemp[j][0];
        }
    }
    if ( Right)
    {
        for (j = 0; j <= degree; j++)
        {
            Right[j] = Vtemp[degree-j][j];
        }
    }
    
    return (Vtemp[degree][0]);
}

static CGPoint V2ScaleII(CGPoint v, double s){
    return CGPointMake(v.x * s, v.y * s);
}

