#ifndef _VECTOR_HPP
#define _VECTOR_HPP

#import <UIKit/UIKit.h>
#import "Foundation/Foundation.h"

typedef int (*QSORTFUNC)( const void *, const void * );

// PDS: PROGRESSFUNC( step, numberSteps, stepPercentage )
typedef void (*PROGRESSFUNC)(int,int,int);

class Vector
{
public:  

  typedef struct VNODE
  {
    int    content_type;
    void  *contents;
    void  *sec_contents;
    double dbl_contents;
    VNODE *next;
    BOOL   deletionMarked;
  } VNODE;
  
  
  BOOL m_AutoFree;
  /*
  BOOL   m_NotifyAddEvent;
  HANDLE evtItemAdded;
  */

  Vector();
  Vector( int num_elements );
  ~Vector();

  void insertElementAt( int element, int nPosn );
  void insertElementAt( char *element, int nPosn );
  void insertElementAt( void *element, int nPosn );
  void insertElementDblAt( double element, int nPosn );

  void addElement( int element );
  void addElement( char *element );
  void addElement( void *element );
  void addElementDbl( double element );

  void addUnique( int element );
  void addUnique( char *element );

  void removeElementAt( int index );
  void removeUniqueElement( int element );
  void removeUniqueElement( char *element );
  
  void removeAll( void );

  BOOL markElementDeletedAt( int index );
  void purgeDeletedElements( void );

  void setElementAt( int index, int element );
  void setElementAt( int index, char *element );
  void setElementAt( int index, void *element );
  void setElementDblAt( int index, double element );
  
  void setSecondaryAt( int index, void *secondary );

  int  elementIntAt( int index );
  char *elementStrAt( int index );
  void *elementPtrAt( int index );
  double elementDblAt( int index );
  void *secondaryPtrAt( int index );

  int  indexOf( int element );
  int  indexOf( char *element, BOOL fCaseSensitive = FALSE );
  int  indexOf( void *element );
  int  indexOfDbl( double element );

  int  indexOf( int element, int start );
  int  indexOf( char *element, int start, BOOL fCaseSensitive = FALSE );
  int  indexOf( void *element, int start );
  int  indexOfDbl( double element, int start );
  
  int  indexOfStringStartingWith( char *pSubstring, BOOL fCaseSensitive = FALSE );
  int  indexOfStringStartingWith( int nStart, char *pSubstring, BOOL fCaseSensitive = FALSE );
  int  indexOfStringEndingWith( char *pSubstring, BOOL fCaseSensitive = FALSE );
  int  indexOfStringEndingWith( int nStart, char *pSubstring, BOOL fCaseSensitive = FALSE );
  int  indexOfStringContaining( char *pSubstring, BOOL fCaseSensitive = FALSE );
  int  indexOfStringContaining( int nStart, char *pSubstring, BOOL fCaseSensitive = FALSE );

  BOOL contains( int element );
  BOOL contains( char *element, BOOL fCaseSensitive = FALSE );
  BOOL contains( void *element );
  BOOL containsDbl( double element );

  int  containsHowMany( int element );
  int  containsHowMany( char *element );
  int  containsHowMany( void *element );
  int  containsHowManyDbl( double element );

  int  elementCount( void );

  void concat( Vector *src );
  void concatUnique( Vector *src );
  void copy( Vector *v );
  void copyTo( Vector *v );

  BOOL sortIntAscending( void );
  BOOL sortDblAscending( void );
  BOOL sortStrAscending( void );
  BOOL sortPtrAscending( QSORTFUNC );

  void *getParent( void );
  void setParent( void *pParent );

  BOOL reverse( void );
  void shuffle( void );
  
  BOOL exportToFile( char *pszTag, char *pszFile, PROGRESSFUNC pfnProgress = NULL, BOOL fAppend = FALSE );
  BOOL importFromFile( char *pszTag, char *pszFile, PROGRESSFUNC pfnProgress = NULL );

  BOOL exportToFileInt( char *pszTag, char *pszFile, PROGRESSFUNC pfnProgress = NULL );
  BOOL importFromFileInt( char *pszTag, char *pszFile, PROGRESSFUNC pfnProgress = NULL );
  
  
private:

  VNODE  *list;
  int     num_nodes;
  VNODE  *last_node;
  VNODE **node_index;
  int     new_node_index;
  int     max_nodes;

  void   *m_pParent;

  VNODE *Goto_Node( int index );
  void   Init( void );
};

#endif
