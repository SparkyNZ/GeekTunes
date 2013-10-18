//--------------------------------------------------------------------------
// CLASS:        Vector()
//
// DESCRIPTIONS: Simple Java-like Vector class
//
// AUTHOR:       Paul D. Spark, November 1997
//               Optimised indexing - April 1998
//               Sorting of strings - Sept  1998
//               Double elements    - Dec   1998
//               Element insertion  - Sept  2005
//               Fixed mem leak     - Nov   2005
//               Added reverse()    - Jul   2010
//               Added m_AutoFree   - Sept  2010
//               Sorting of records - Oct   2010
//               Add notify event   - Feb   2011
//               Added matching     - Jul   2012
//--------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//#ifndef _WIN32
//#include "MyTypes.h"
//#endif

#include "vector.h"
#include "Utils.h"

#define CT_INT 0
#define CT_STR 1
#define CT_PTR 2
#define CT_DBL 3

#define LF 0x0A
#define CR 0x0D

#define DEFAULT_NUM_NODES   200
#define DEFAULT_EXTRA_NODES 100

//#define DEFAULT_NUM_NODES   4000
//#define DEFAULT_EXTRA_NODES 4000

int Qsort_Int_Compare( const void *arg1, const void *arg2 );
int Qsort_Dbl_Compare( const void *arg1, const void *arg2 );
int Qsort_Str_Compare( const void *arg1, const void *arg2 );
int Qsort_Str_Compare2( const void *arg1, const void *arg2 );

//--------------------------------------------------------------------------
// Vector() - constructor..
//--------------------------------------------------------------------------
Vector::Vector()
{
  max_nodes      = DEFAULT_NUM_NODES;
  
  Init();
}

//--------------------------------------------------------------------------
// Vector() - constructor for user who has a rough idea of how many elements
//--------------------------------------------------------------------------
Vector::Vector( int num_elements )
{
  max_nodes      = num_elements;
  
  Init();
}

//--------------------------------------------------------------------------
// Init()
//--------------------------------------------------------------------------
void Vector::Init( void )
{
  list             = NULL;
  last_node        = NULL;
  num_nodes        = 0;
  
  new_node_index   = 0;
  node_index       = ( VNODE ** ) malloc( sizeof( VNODE * ) * max_nodes );
  m_pParent        = NULL;
  m_AutoFree       = FALSE;
  
  /*
  m_NotifyAddEvent = FALSE;
  
  evtItemAdded = CreateEvent( NULL, FALSE, FALSE, NULL );
   */
}

//--------------------------------------------------------------------------
// Vector() - destructor.. frees up memory used to store the nodes
//--------------------------------------------------------------------------
Vector::~Vector()
{
  VNODE *temp, *next_node;
  int node;
  
  temp = list;
  
  for( node = 0; node < num_nodes; node ++ )
  {
    if( temp ) 
    {
      // PDS: Make sure string contents are freed - malloc() is used to create the
      //      string duplicates..
      if( ( temp->content_type == CT_STR ) && ( temp->contents ) )
        free( temp->contents );
      else
        if( ( temp->content_type == CT_PTR ) && ( temp->contents ) && ( m_AutoFree ) )
          free( temp->contents );
      
      next_node = temp->next;
      free( temp );
      temp = next_node;
    }
    else
      break;
  }
  
  if( node_index )
    free( node_index );
  
  //CloseHandle( evtItemAdded );
}


//--------------------------------------------------------------------------
// addElement() - 
//--------------------------------------------------------------------------
void Vector::addElement( int element )
{
  VNODE *new_node;
  
  new_node = (VNODE *) malloc( sizeof( VNODE ) );
  
  if( new_node )
  {
    new_node->next           = NULL;
    new_node->contents       = (void *) element;
    new_node->sec_contents   = 0;
    new_node->content_type   = CT_INT;
    new_node->deletionMarked = FALSE;
    
    if( num_nodes == 0 )
    {
      list = new_node;
      last_node = list;
    }
    else
    {
      last_node->next = new_node;
      last_node = new_node;
    }
    
    num_nodes ++;
    
    // Maintain the node index.. We may also need to ensure that we haven't
    // exceeded the number of nodes we originally "guess" allocated for..
    
    if( new_node_index >= max_nodes )
    {
      // Rather than keep reallocating for each additional node that goes over
      // the top of the declared size, we'll allocate an additional block of new
      // nodes (ie. an extra 100 or so)
      
      max_nodes += DEFAULT_EXTRA_NODES;
      
      node_index = ( VNODE ** ) realloc( node_index, 
                                        sizeof( VNODE * ) * max_nodes );
    }
    
    node_index[ new_node_index ] = new_node;
    new_node_index ++;
    
    // PDS: Allow application to act when node is added..
    //if( m_NotifyAddEvent )
      //SetEvent( evtItemAdded );
  }
}


//--------------------------------------------------------------------------
// addElementDbl() - 
//--------------------------------------------------------------------------
void Vector::addElementDbl( double element )
{
  VNODE *new_node;
  
  new_node = (VNODE *) malloc( sizeof( VNODE ) );
  
  if( new_node )
  {
    new_node->next           = NULL;
    new_node->dbl_contents   = element;
    new_node->sec_contents   = 0;
    new_node->content_type   = CT_DBL;
    new_node->deletionMarked = FALSE;    
    
    if( num_nodes == 0 )
    {
      list = new_node;
      last_node = list;
    }
    else
    {
      last_node->next = new_node;
      last_node = new_node;
    }
    
    num_nodes ++;
    
    // Maintain the node index.. We may also need to ensure that we haven't
    // exceeded the number of nodes we originally "guess" allocated for..
    
    if( new_node_index >= max_nodes )
    {
      // Rather than keep reallocating for each additional node that goes over
      // the top of the declared size, we'll allocate an additional block of new
      // nodes (ie. an extra 100 or so)
      
      max_nodes += DEFAULT_EXTRA_NODES;
      
      node_index = ( VNODE ** ) realloc( node_index, 
                                        sizeof( VNODE * ) * max_nodes );
    }
    
    node_index[ new_node_index ] = new_node;
    new_node_index ++;
    
    // PDS: Allow application to act when node is added..
    //if( m_NotifyAddEvent )
      //SetEvent( evtItemAdded );
  }
}


//--------------------------------------------------------------------------
// addElement() - 
//--------------------------------------------------------------------------
void Vector::addElement( char *element )
{
  VNODE *new_node;
  
  new_node = (VNODE *) malloc( sizeof( VNODE ) );
  
  if( new_node )
  {
    new_node->next           = NULL;
    new_node->sec_contents   = 0;
    new_node->contents       = malloc( strlen( element ) + 1 );
    new_node->content_type   = CT_STR;    
    new_node->deletionMarked = FALSE;
    
    strcpy( (char *) new_node->contents, element );
    
    if( num_nodes == 0 )
    {
      list = new_node;
      last_node = list;
    }
    else
    {
      last_node->next = new_node;
      last_node = new_node;
    }
    
    num_nodes ++;
    
    // Maintain the node index.. We may also need to ensure that we haven't
    // exceeded the number of nodes we originally "guess" allocated for..
    
    node_index[ new_node_index ] = new_node;
    new_node_index ++;
    
    if( new_node_index >= max_nodes )
    {
      // Rather than keep reallocating for each additional node that goes over
      // the top of the declared size, we'll allocate an additional block of new
      // nodes (ie. an extra 100 or so)
      
      max_nodes += DEFAULT_EXTRA_NODES;
      
      node_index = ( VNODE ** ) realloc( node_index, 
                                        sizeof( VNODE * ) * max_nodes );
    }
    
    // PDS: Allow application to act when node is added..
    //if( m_NotifyAddEvent )
      //SetEvent( evtItemAdded );
  }
}


//--------------------------------------------------------------------------
// addElement() - 
//--------------------------------------------------------------------------
void Vector::addElement( void *element )
{
  VNODE *new_node;
  
  new_node = (VNODE *) malloc( sizeof( VNODE ) );
  
  if( new_node )
  {
    new_node->next           = NULL;
    new_node->sec_contents   = 0;
    new_node->contents       = element;
    new_node->content_type   = CT_PTR;    
    new_node->deletionMarked = FALSE;
    
    if( num_nodes == 0 )
    {
      list = new_node;
      last_node = list;
    }
    else
    {
      last_node->next = new_node;
      last_node = new_node;
    }
    
    num_nodes ++;
    
    // Maintain the node index.. We may also need to ensure that we haven't
    // exceeded the number of nodes we originally "guess" allocated for..
    
    node_index[ new_node_index ] = new_node;
    new_node_index ++;
    
    if( new_node_index >= max_nodes )
    {
      // Rather than keep reallocating for each additional node that goes over
      // the top of the declared size, we'll allocate an additional block of new
      // nodes (ie. an extra 100 or so)
      
      max_nodes += DEFAULT_EXTRA_NODES;
      
      node_index = ( VNODE ** ) realloc( node_index, 
                                        sizeof( VNODE * ) * max_nodes );
    }
    
    // PDS: Allow application to act when node is added..
    //if( m_NotifyAddEvent )
      //SetEvent( evtItemAdded );
  }
}


//--------------------------------------------------------------------------
// insertElementAt() - 
//--------------------------------------------------------------------------
void Vector::insertElementAt( char *element, int nPosn )
{
  // PDS: Get stuffed - no nodes, forget insertion! Use addElement() instead..
  if( num_nodes < 1 )
  {
    addElement( element );
    return;
  }
  
  // PDS: Can't insert into nowhere..
  if( nPosn > num_nodes )
    return;
  
  // PDS: You want to put it on the end - use the method already there..
  if( nPosn == num_nodes )
  {
    addElement( element );
    return;
  }
  
  VNODE *new_node;
  
  new_node = (VNODE *) malloc( sizeof( VNODE ) );
  
  if( ! new_node )
    return;
  
  new_node->next           = NULL;
  new_node->sec_contents   = 0;
  new_node->contents       = (void *) malloc( strlen( element ) + 1 );
  new_node->content_type   = CT_STR;    
  new_node->deletionMarked = FALSE;
  
  strcpy( (char *) new_node->contents, element );
  
  num_nodes ++;
  
  VNODE *curr;
  
  curr = node_index[ nPosn ];
  
  new_node->next = curr;
  
  if( nPosn > 0 )
  {
    VNODE *prev;
    
    // A node is being inserted in the middle somewhere..
    prev = node_index[ nPosn - 1 ];
    
    // PDS: In it goes..
    prev->next     = new_node;
  }
  else
  {
    list = new_node;
  }
  
  // Maintain the node index.. We may also need to ensure that we haven't
  // exceeded the number of nodes we originally "guess" allocated for..
  
  if( new_node_index >= max_nodes )
  {
    // Rather than keep reallocating for each additional node that goes over
    // the top of the declared size, we'll allocate an additional block of new
    // nodes (ie. an extra 100 or so)
    
    max_nodes += DEFAULT_EXTRA_NODES;
    
    node_index = ( VNODE ** ) realloc( node_index, 
                                      sizeof( VNODE * ) * max_nodes );
  }
  
  long lNodesToRight = max_nodes - 1 - nPosn;
  long lMemToMove    = sizeof( VNODE * ) * lNodesToRight;
  
  // PDS: Push all the indices along to the right to make way..
  memmove( &node_index[ nPosn + 1 ], 
          &node_index[ nPosn     ], 
          lMemToMove );
  
  node_index[ nPosn ] = new_node;
  new_node_index ++;
  
  // PDS: Allow application to act when node is added..
  //if( m_NotifyAddEvent )
    //SetEvent( evtItemAdded );
}


//--------------------------------------------------------------------------
// insertElementAt() - 
//--------------------------------------------------------------------------
void Vector::insertElementAt( void *element, int nPosn )
{
  // PDS: Get stuffed - no nodes, forget insertion! Use addElement() instead..
  if( num_nodes < 1 )
  {
    addElement( element );
    return;
  }
  
  // PDS: Can't insert into nowhere..
  if( nPosn > num_nodes )
    return;
  
  // PDS: You want to put it on the end - use the method already there..
  if( nPosn == num_nodes )
  {
    addElement( element );
    return;
  }
  
  VNODE *new_node;
  new_node = (VNODE *) malloc( sizeof( VNODE ) );
  
  if( ! new_node )
    return;
  
  new_node->next           = NULL;
  new_node->sec_contents   = 0;
  new_node->contents       = (void *) element;
  new_node->content_type   = CT_PTR;
  new_node->deletionMarked = FALSE;
  
  num_nodes ++;
  
  VNODE *curr;
  
  curr = node_index[ nPosn ];
  
  new_node->next = curr;
  
  if( nPosn > 0 )
  {
    VNODE *prev;
    
    // A node is being inserted in the middle somewhere..
    prev = node_index[ nPosn - 1 ];
    
    // PDS: In it goes..
    prev->next     = new_node;
  }
  else
  {
    list = new_node;
  }
  
  // Maintain the node index.. We may also need to ensure that we haven't
  // exceeded the number of nodes we originally "guess" allocated for..
  
  if( new_node_index >= max_nodes )
  {
    // Rather than keep reallocating for each additional node that goes over
    // the top of the declared size, we'll allocate an additional block of new
    // nodes (ie. an extra 100 or so)
    
    max_nodes += DEFAULT_EXTRA_NODES;
    
    node_index = ( VNODE ** ) realloc( node_index, 
                                      sizeof( VNODE * ) * max_nodes );
  }
  
  long lNodesToRight = max_nodes - 1 - nPosn;
  long lMemToMove    = sizeof( VNODE * ) * lNodesToRight;
  
  // PDS: Push all the indices along to the right to make way..
  memmove( &node_index[ nPosn + 1 ], 
          &node_index[ nPosn     ], 
          lMemToMove );
  
  node_index[ nPosn ] = new_node;
  new_node_index ++;
  
  // PDS: Allow application to act when node is added..
  //if( m_NotifyAddEvent )
    //SetEvent( evtItemAdded );
}


//--------------------------------------------------------------------------
// insertElementDblAt() - 
//--------------------------------------------------------------------------
void Vector::insertElementDblAt( double element, int nPosn )
{
  // PDS: Get stuffed - no nodes, forget insertion! Use addElement() instead..
  if( num_nodes < 1 )
  {
    addElementDbl( element );
    return;
  }
  
  // PDS: Can't insert into nowhere..
  if( nPosn > num_nodes )
    return;
  
  // PDS: You want to put it on the end - use the method already there..
  if( nPosn == num_nodes )
  {
    addElementDbl( element );
    return;
  }
  
  VNODE *new_node;  new_node = (VNODE *) malloc( sizeof( VNODE ) );
  
  if( ! new_node )
    return;
  
  new_node->next           = NULL;
  new_node->sec_contents   = 0;
  new_node->dbl_contents   = element;
  new_node->content_type   = CT_DBL;
  new_node->deletionMarked = FALSE;
  
  num_nodes ++;
  
  VNODE *curr;
  
  curr = node_index[ nPosn ];
  
  new_node->next = curr;
  
  if( nPosn > 0 )
  {
    VNODE *prev;
    
    // A node is being inserted in the middle somewhere..
    prev = node_index[ nPosn - 1 ];
    
    // PDS: In it goes..
    prev->next     = new_node;
  }
  else
  {
    list = new_node;
  }
  
  // Maintain the node index.. We may also need to ensure that we haven't
  // exceeded the number of nodes we originally "guess" allocated for..
  
  if( new_node_index >= max_nodes )
  {
    // Rather than keep reallocating for each additional node that goes over
    // the top of the declared size, we'll allocate an additional block of new
    // nodes (ie. an extra 100 or so)
    
    max_nodes += DEFAULT_EXTRA_NODES;
    
    node_index = ( VNODE ** ) realloc( node_index, 
                                      sizeof( VNODE * ) * max_nodes );
  }
  
  long lNodesToRight = max_nodes - 1 - nPosn;
  long lMemToMove    = sizeof( VNODE * ) * lNodesToRight;
  
  // PDS: Push all the indices along to the right to make way..
  memmove( &node_index[ nPosn + 1 ], 
          &node_index[ nPosn     ], 
          lMemToMove );
  
  node_index[ nPosn ] = new_node;
  new_node_index ++;
  
  // PDS: Allow application to act when node is added..
  //if( m_NotifyAddEvent )
    //SetEvent( evtItemAdded );
}


//--------------------------------------------------------------------------
// insertElementAt() - 
//--------------------------------------------------------------------------
void Vector::insertElementAt( int element, int nPosn )
{
  // PDS: Get stuffed - no nodes, forget insertion! Use addElement() instead..
  if( num_nodes < 1 )
  {
    addElement( element );
    return;
  }
  
  // PDS: Can't insert into nowhere..
  if( nPosn > num_nodes )
    return;
  
  // PDS: You want to put it on the end - use the method already there..
  if( nPosn == num_nodes )
  {
    addElement( element );
    return;
  }
  
  VNODE *new_node;
  new_node = (VNODE *) malloc( sizeof( VNODE ) );
  
  if( ! new_node )
    return;
  
  new_node->next           = NULL;
  new_node->sec_contents   = 0;
  new_node->contents       = (void *) element;
  new_node->content_type   = CT_INT;
  new_node->deletionMarked = FALSE;
  
  num_nodes ++;
  
  VNODE *curr;
  
  curr = node_index[ nPosn ];
  
  new_node->next = curr;
  
  if( nPosn > 0 )
  {
    VNODE *prev;
    
    // A node is being inserted in the middle somewhere..
    prev = node_index[ nPosn - 1 ];
    
    // PDS: In it goes..
    prev->next     = new_node;
  }
  else
  {
    list = new_node;
  }
  
  // Maintain the node index.. We may also need to ensure that we haven't
  // exceeded the number of nodes we originally "guess" allocated for..
  
  if( new_node_index >= max_nodes )
  {
    // Rather than keep reallocating for each additional node that goes over
    // the top of the declared size, we'll allocate an additional block of new
    // nodes (ie. an extra 100 or so)
    
    max_nodes += DEFAULT_EXTRA_NODES;
    
    node_index = ( VNODE ** ) realloc( node_index, 
                                      sizeof( VNODE * ) * max_nodes );
  }
  
  long lNodesToRight = max_nodes - 1 - nPosn;
  long lMemToMove    = sizeof( VNODE * ) * lNodesToRight;
  
  // PDS: Push all the indices along to the right to make way..
  memmove( &node_index[ nPosn + 1 ], 
          &node_index[ nPosn     ], 
          lMemToMove );
  
  node_index[ nPosn ] = new_node;
  new_node_index ++;
  
  // PDS: Allow application to act when node is added..
  //if( m_NotifyAddEvent )
    //SetEvent( evtItemAdded );
}


//--------------------------------------------------------------------------
// Goto_Node() - returns a pointer to a node at the specified index
//--------------------------------------------------------------------------
Vector::VNODE *Vector::Goto_Node( int index )
{
  // If somebody's attempted to access a non-existent node, bail out..
  if( ( index < 0 ) || ( index >= num_nodes ) )
    return NULL;
  
  return node_index[ index ];
}


/* PDS> OLD & INEFFICIENT
//--------------------------------------------------------------------------
// removeAll() - remove all elements from this list
//--------------------------------------------------------------------------
void Vector::removeAll( void )
{
  int temp_num_nodes = num_nodes;
  int node;
  
  for( node = 0; node < temp_num_nodes; node ++ )
    removeElementAt( 0 );
  
  // Reset the index table pointer for new nodes..
  new_node_index = 0;
}
 */


 //--------------------------------------------------------------------------
 // removeAll() - remove all elements from this list
 //--------------------------------------------------------------------------
 void Vector::removeAll( void )
 {
   int temp_num_nodes = num_nodes;
   int node;
   
   VNODE *node_to_kill;
   
   for( node = 0; node < temp_num_nodes; node ++ )
   {
     node_to_kill = node_index[ node ];
     
     if( node_to_kill->content_type == CT_STR )
       free( node_to_kill->contents );
     else
     if( ( node_to_kill->content_type == CT_PTR ) && ( m_AutoFree ) )
       free( node_to_kill->contents );
     
     free( node_to_kill );
   }
   
   num_nodes = 0;
   list      = NULL;
   last_node = NULL;
   
   // Reset the index table pointer for new nodes..
   new_node_index = 0;
 }

//--------------------------------------------------------------------------
// removeElementAt() -
//--------------------------------------------------------------------------
void Vector::removeElementAt( int index )
{
  VNODE *node_to_kill;
  VNODE *prev;
  VNODE *next;
  
  if( num_nodes == 0 )
    return;
  
  node_to_kill = node_index[ index ];
  
  // If somebody's attempted to delete a non-existent node, bail out..
  if( !node_to_kill )
    return;
  
  next = node_to_kill->next;
  
  if( ( num_nodes > 1 ) && ( index > 0 ) )
  {
    // A node somewhere in the middle is being deleted..
    prev = node_index[ index - 1 ];
    prev->next = next;
    
    // If we're removing the last node then last_node needs to be reassigned..
    
    if( node_to_kill == last_node )
      last_node = prev;
  }
  else
  if( ( num_nodes > 1 ) && ( index == 0 ) )
  {
    // First node being deleted, other nodes still exist..
    list = node_to_kill->next;
    
    // last_node remains the same if we're removing the first node
  }
  else
  {
    // The only remaining node is being deleted..
    list      = NULL;
    last_node = NULL;
  }
  
  //------------------------------------------------------------------------
  // Handle the node indices separately (for now)..
  //------------------------------------------------------------------------
  if( index != ( num_nodes - 1 ) )
  {
    int index_after_del_node = ( index + 1 );
    int nodes_to_move        = ( new_node_index - index_after_del_node );
    
    // We've deleted any node other than the last.. We need to move the node
    // index pointers up a position, filling up the gap of the index used by the
    // deleted node.
    //
    // i.e.
    // 0 1 2 3 4 5 ..
    // A B C D E F  - delete node 2, item C
    //
    // 0 1 2 3 4 5 .. 
    // A B   D E F  - need to shift D, E & F up one space to keep indexing correct
    //
    // 0 1 2 3 4 5 ..
    // A B D E F    - result
    
    // Now move the "D E F" up as described above..
    
    memmove( &node_index[ index ], 
             &node_index[ index_after_del_node ],
             sizeof( VNODE * ) * nodes_to_move );
  }
  
  // Since we only ever delete one node, the next new node space will always be
  // one less than previous..
  new_node_index --;  
  
  num_nodes --;
  
  if( node_to_kill->content_type == CT_STR )
    free( node_to_kill->contents );
  else
  if( ( node_to_kill->content_type == CT_PTR ) && ( m_AutoFree ) )
    free( node_to_kill->contents );
  
  free( node_to_kill );
}

//--------------------------------------------------------------------------
// setSecondaryAt() -
//--------------------------------------------------------------------------
void Vector::setSecondaryAt( int index, void *secondary )
{
  VNODE *temp = node_index[ index ];
  
  if( temp )
    temp->sec_contents = secondary;
}

//--------------------------------------------------------------------------
// setElementAt() - 
//--------------------------------------------------------------------------
void Vector::setElementAt( int index, int element )
{
  VNODE *temp = node_index[ index ];
  
  if( temp )
  {
    if( temp->content_type == CT_STR )
      free( temp->contents );
    
    if( ( temp->content_type == CT_PTR ) && ( m_AutoFree ) )
      free( temp->contents );
    
    temp->content_type = CT_INT;    
    temp->contents = (void *)element;
  }
}

//--------------------------------------------------------------------------
// setElementDblAt() - 
//--------------------------------------------------------------------------
void Vector::setElementDblAt( int index, double element )
{
  VNODE *temp = node_index[ index ];
  
  if( temp )
  {
    if( temp->content_type == CT_STR )
      free( temp->contents );
    
    if( ( temp->content_type == CT_PTR ) && ( m_AutoFree ) )
      free( temp->contents );
    
    temp->content_type = CT_DBL;    
    temp->dbl_contents = element;
  }
}



//--------------------------------------------------------------------------
// setElementAt() - 
//--------------------------------------------------------------------------
void Vector::setElementAt( int index, char *element )
{
  VNODE *temp = node_index[ index ];
  
  if( temp )
  {
    if( temp->content_type == CT_STR )
      free( temp->contents );
    
    if( ( temp->content_type == CT_PTR ) && ( m_AutoFree ) )
      free( temp->contents );
    
    temp->contents = malloc( strlen( element ) + 1 );
    temp->content_type = CT_STR;    
    strcpy( (char *)temp->contents, element );
  }
}



//--------------------------------------------------------------------------
// setElementAt() - 
//--------------------------------------------------------------------------
void Vector::setElementAt( int index, void *element )
{
  VNODE *temp = node_index[ index ];
  
  if( temp )
  {
    if( temp->content_type == CT_STR )
      free( temp->contents );
    
    if( ( temp->content_type == CT_PTR ) && ( m_AutoFree ) )
      free( temp->contents );
    
    temp->contents = element;
    temp->content_type = CT_PTR;    
  }
}



//--------------------------------------------------------------------------
// elementIntAt() - returns the element at the requested index
//--------------------------------------------------------------------------
int Vector::elementIntAt( int index )
{
  VNODE *temp = node_index[ index ];
  
  if( temp )
    return (int) temp->contents;
  else
    return 0;
}



//--------------------------------------------------------------------------
// elementDblAt() - returns the element at the requested index
//--------------------------------------------------------------------------
double Vector::elementDblAt( int index )
{
  VNODE *temp = node_index[ index ];
  
  if( temp )
    return temp->dbl_contents;
  else
    return 0;
}

//--------------------------------------------------------------------------
// elementStrAt() - returns the element at the requested index
//--------------------------------------------------------------------------
char *Vector::elementStrAt( int index )
{
  VNODE *temp = node_index[ index ];
  
  if( temp && temp->content_type == CT_STR )
    return (char *) temp->contents;
  else
    return NULL;
}

//--------------------------------------------------------------------------
// secondaryPtrAt() - returns the element at the requested index
//--------------------------------------------------------------------------
void *Vector::secondaryPtrAt( int index )
{
  VNODE *temp = node_index[ index ];
  
  if( temp  )
    return (void *) temp->sec_contents;
  else
    return NULL;
}

//--------------------------------------------------------------------------
// elementPtrAt() - returns the element at the requested index
//--------------------------------------------------------------------------
void *Vector::elementPtrAt( int index )
{
  VNODE *temp = node_index[ index ];
  
  if( temp && temp->content_type == CT_PTR )
    return (void *) temp->contents;
  else
    return NULL;
}

//--------------------------------------------------------------------------
// indexOf() - returns the index of the next occurrence of the given element
//             from the start position
//--------------------------------------------------------------------------
int Vector::indexOf( int element, int start )
{
  VNODE *temp;
  
  for( int n = start; n < num_nodes; n ++ )
  {
    temp = node_index[ n ];
    
    if( !temp )
      return -1;
    
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
      continue;
    
    if( temp->contents == (void *)element )
      return n;
  }
  
  return -1;
}



//--------------------------------------------------------------------------
// indexOf() - returns the index of the first occurrence of the requested
//             element.. or -1 if it doesn't exist
//--------------------------------------------------------------------------
int Vector::indexOf( int element )
{
  return indexOf( element, 0 );
}


//--------------------------------------------------------------------------
// indexOfDbl() - returns the index of the next occurrence of the given element
//                from the start position
//--------------------------------------------------------------------------
int Vector::indexOfDbl( double element, int start )
{
  VNODE *temp;
  
  for( int n = start; n < num_nodes; n ++ )
  {
    temp = node_index[ n ];
    
    if( !temp )
      return -1;
    
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
      continue;
    
    if( temp->dbl_contents == element )
      return n;
  }
  
  return -1;
}


//--------------------------------------------------------------------------
// indexOf() - returns the index of the first occurrence of the requested
//             element.. or -1 if it doesn't exist
//--------------------------------------------------------------------------
int Vector::indexOfDbl( double element )
{
  return indexOfDbl( element, 0 );
}


//--------------------------------------------------------------------------
// indexOf() - returns the index of the next occurrence of the given element
//             from the start position
//--------------------------------------------------------------------------
int Vector::indexOf( char *element, int start, BOOL fCaseSensitive )
{
  VNODE *temp;
  
  for( int n = start; n < num_nodes; n ++ )
  {
    temp = node_index[ n ];
    
    if( !temp )
      return -1;
    
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
      continue;
    
    if( fCaseSensitive )
    {
      if( ! strcmp( (char *)temp->contents, element ) )
        return n;
    }
    else
    {
      if( ! stricmp( (char *)temp->contents, element ) )
        return n;
    }
  }
  
  return -1;
}

//--------------------------------------------------------------------------
// indexOfStringContaining() - returns the index of the next element 
//                             containing a given string (ie. partial match)
//--------------------------------------------------------------------------
int Vector::indexOfStringContaining( int nStart, char *pSubstring, BOOL fCaseSensitive )
{
  VNODE *temp;
  
  for( int n = nStart; n < num_nodes; n ++ )
  {
    temp = node_index[ n ];
    
    if( ! temp )
      return -1;
    
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
      continue;
    
    char *pElement = (char *)temp->contents;
    
    if( fCaseSensitive )
    {
      if( strstr( pElement, pSubstring ) )
        return n;
    }
    else
    {
      if( stristr( pElement, pSubstring ) )
        return n;
    }
  }
  
  return -1;
}

//--------------------------------------------------------------------------
// indexOfStringContaining() - returns the index of the next element 
//                             containing a given string (ie. partial match)
//--------------------------------------------------------------------------
int Vector::indexOfStringContaining( char *pSubstring, BOOL fCaseSensitive )
{
  return indexOfStringContaining( 0, pSubstring, fCaseSensitive );
}

//--------------------------------------------------------------------------
// indexOfStringStartingWith() - returns the index of the next element 
//                               starting with a given string (ie. partial match)
//--------------------------------------------------------------------------
int Vector::indexOfStringStartingWith( int nStart, char *pSubstring, BOOL fCaseSensitive )
{
  VNODE *temp;
  int    nSubstrLen = strlen( pSubstring );
  
  for( int n = nStart; n < num_nodes; n ++ )
  {
    temp = node_index[ n ];
    
    if( ! temp )
      return -1;
    
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
      continue;
    
    char *pElement = (char *)temp->contents;
    
    if( fCaseSensitive )
    {
      if( ! strncmp( pElement, pSubstring, nSubstrLen ) )
        return n;
    }
    else
    {
      if( ! _strnicmp( pElement, pSubstring, nSubstrLen ) )
        return n;
    }
  }
  
  return -1;
}

//--------------------------------------------------------------------------
// indexOfStringStartingWith() - returns the index of the next element 
//                               starting with a given string (ie. partial match)
//--------------------------------------------------------------------------
int Vector::indexOfStringStartingWith( char *pSubstring, BOOL fCaseSensitive )
{
  return indexOfStringStartingWith( 0, pSubstring, fCaseSensitive );
}

//--------------------------------------------------------------------------
// indexOfStringEndingWith() - returns the index of the next element 
//                             ending with a given string (ie. partial match)
//--------------------------------------------------------------------------
int Vector::indexOfStringEndingWith( int nStart, char *pSubstring, BOOL fCaseSensitive )
{
  VNODE *temp;
  char  *pElement;
  int    nSubstrLen = strlen( pSubstring );
  int    nElementLen;
  
  for( int n = nStart; n < num_nodes; n ++ )
  {
    temp = node_index[ n ];
    
    if( ! temp )
      return -1;
    
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
      continue;
    
    pElement    = (char *)temp->contents;
    nElementLen = strlen( pElement );
    
    // PDS: Skip if element is too small to match..
    if( nElementLen < nSubstrLen )
      continue;
    
    char *pMatchPosn = &pElement[ nElementLen - nSubstrLen ];
    
    if( fCaseSensitive )
    {
      if( ! strcmp( pMatchPosn, pSubstring ) )
        return n;
    }
    else
    {
      if( ! stricmp( pMatchPosn, pSubstring ) )
        return n;
    }
  }
  
  return -1;
}

//--------------------------------------------------------------------------
// indexOfStringEndingWith() - returns the index of the next element 
//                             ending with a given string (ie. partial match)
//--------------------------------------------------------------------------
int Vector::indexOfStringEndingWith( char *element, BOOL fCaseSensitive )
{
  return indexOfStringEndingWith( 0, element, fCaseSensitive );
}

//--------------------------------------------------------------------------
// indexOf() - returns the index of the next occurrence of the given element
//             from the start position
//--------------------------------------------------------------------------
int Vector::indexOf( void *element, int start )
{
  VNODE *temp;
  
  for( int n = start; n < num_nodes; n ++ )
  {
    temp = node_index[ n ];
    
    if( !temp )
      return -1;
    
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
      continue;
    
    if( temp->contents == element ) 
      return n;
  }
  
  return -1;
}


//--------------------------------------------------------------------------
// indexOf() - returns the index of the first occurrence of the requested
//             element.. or -1 if it doesn't exist
//--------------------------------------------------------------------------
int Vector::indexOf( void *element )
{
  return indexOf( element, 0 );
}


//--------------------------------------------------------------------------
// indexOf() - returns the index of the first occurrence of the requested
//             element.. or -1 if it doesn't exist
//--------------------------------------------------------------------------
int Vector::indexOf( char *element, BOOL fCaseSensitive )
{
  return indexOf( element, 0, fCaseSensitive );
}


//--------------------------------------------------------------------------
// contains() - returns true if the vector contains the element
//--------------------------------------------------------------------------
BOOL Vector::contains( int element )
{
  if( indexOf( element ) != -1 )
    return TRUE;
  else
    return FALSE;
}


//--------------------------------------------------------------------------
// contains() - returns true if the vector contains the element
//--------------------------------------------------------------------------
BOOL Vector::containsDbl( double element )
{
  if( indexOfDbl( element ) != -1 )
    return TRUE;
  else
    return FALSE;
}


//--------------------------------------------------------------------------
// contains() - returns true if the vector contains the element
//--------------------------------------------------------------------------
BOOL Vector::contains( char *element, BOOL fCaseSensitive )
{
  if( indexOf( element, 0, fCaseSensitive ) != -1 )
    return TRUE;
  else
    return FALSE;
}


//--------------------------------------------------------------------------
// contains() - returns true if the vector contains the element
//--------------------------------------------------------------------------
BOOL Vector::contains( void *element )
{
  if( indexOf( element ) != -1 )
    return TRUE;
  else
    return FALSE;
}


//--------------------------------------------------------------------------
// containsHowMany() - returns how many of the given element exist
//--------------------------------------------------------------------------
int Vector::containsHowMany( int element )
{
  VNODE *temp;
  int   count = 0;
  
  for( int n = 0; n < num_nodes; n ++ )
  {
    temp = node_index[ n ];
    
    if( !temp )
      return -1;
    
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
      continue;
    
    if( temp->contents == (void *) element )
      count ++;
  }
  
  return count;
}


//--------------------------------------------------------------------------
// containsHowMany() - returns how many of the given element exist
//--------------------------------------------------------------------------
int Vector::containsHowManyDbl( double element )
{
  VNODE *temp;
  int   count = 0;
  
  for( int n = 0; n < num_nodes; n ++ )
  {
    temp = node_index[ n ];
    
    if( !temp )
      return -1;
    
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
      continue;
    
    if( temp->content_type == CT_DBL )
    {
      if( temp->dbl_contents == element )
        count ++;
    }
  }
  
  return count;
}


//--------------------------------------------------------------------------
// containsHowMany() - returns how many of the given element exist
//--------------------------------------------------------------------------
int Vector::containsHowMany( char *element )
{
  VNODE *temp;
  int   count = 0;
  
  for( int n = 0; n < num_nodes; n ++ )
  {
    temp = node_index[ n ];
    
    if( !temp )
      return -1;
    
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
      continue;
    
    if( ! strcmp( (char *) temp->contents, element ) )
      count ++;
  }
  
  return count;
}


//--------------------------------------------------------------------------
// containsHowMany() - returns how many of the given element exist
//--------------------------------------------------------------------------
int Vector::containsHowMany( void *element )
{
  VNODE *temp;
  int   count = 0;
  
  for( int n = 0; n < num_nodes; n ++ )
  {
    temp = node_index[ n ];
    
    if( !temp )
      return -1;
    
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
      continue;
    
    if( temp->contents == element )
      count ++;
  }
  
  return count;
}


//--------------------------------------------------------------------------
// elementCount() - returns the number of elements in the list
//--------------------------------------------------------------------------
int Vector::elementCount( void )
{
  return num_nodes;
}


//--------------------------------------------------------------------------
// concat() - adds the string vector src to the end of this vector
//--------------------------------------------------------------------------
void Vector::concat( Vector *src )
{
  VNODE *temp;
  
  for( int index = 0; index < src->elementCount(); index ++ )
  {
    temp = src->node_index[ index ];
    
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
      continue;
    
    if( temp->content_type == CT_INT )
      addElement( src->elementIntAt( index ) );
    else
      if( temp->content_type == CT_DBL )
        addElementDbl( src->elementDblAt( index ) );
      else
        if( temp->content_type == CT_STR )
          addElement( src->elementStrAt( index ) );
        else
          addElement( src->elementPtrAt( index ) );
  }
}


//--------------------------------------------------------------------------
// concatUnique() - adds the unique contents of a vector.. but the dest
//                  vector is allowed to contain non-unique members
//--------------------------------------------------------------------------
void Vector::concatUnique( Vector *src )
{
  VNODE *temp;
  
  for( int index = 0; index < src->elementCount(); index ++ )
  {
    temp = src->node_index[ index ];
    
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
      continue;
    
    if( temp->content_type == CT_INT )
    {
      int element = src->elementIntAt( index );
      
      if( ! contains( element ) )
        addElement( element );
    }
    else
      if( temp->content_type == CT_DBL )
      {
        double element = src->elementDblAt( index );
        
        if( ! containsDbl( element ) )
          addElementDbl( element );
      }
      else
        if( temp->content_type == CT_STR )
        {
          char *element = src->elementStrAt( index );
          
          if( ! contains( element ) )
            addElement( element );
        }
        else
        {
          void *element = src->elementPtrAt( index );
          
          if( ! contains( element ) )
            addElement( element );
        }
    
  }
}

//--------------------------------------------------------------------------
// copy() - copies the contents of vector v into this vector
//--------------------------------------------------------------------------
void Vector::copy( Vector *v )
{
  VNODE *temp;
  
  removeAll();
  
  temp = v->list;
  
  for( int index = 0; index < v->elementCount(); index ++ )
  {
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
    {
      temp = temp->next;
      continue;
    }
    
    if( temp->content_type == CT_INT )
      addElement( v->elementIntAt( index ) );
    else
      if( temp->content_type == CT_DBL )
        addElementDbl( v->elementDblAt( index ) );
      else
        if( temp->content_type == CT_STR )
          addElement( v->elementStrAt( index ) );
        else
          addElement( v->elementPtrAt( index ) );
    
    setSecondaryAt( elementCount() - 1, v->secondaryPtrAt( index ) );
    
    temp = temp->next;
  }
}

//--------------------------------------------------------------------------
// sortIntAscending() - sorts a vector into ascending order (numeric only)
//                      This method will return TRUE if successful.
//--------------------------------------------------------------------------
BOOL Vector::sortIntAscending( void )
{
  int   index;
  int   *array;
  VNODE *temp;
  
  // In order to make use of the ANSI qsort() function we need the vector
  // converted into an array. 
  
  array = (int *) malloc( sizeof( int ) * elementCount() );
  
  if( !array )
    return FALSE;
  
  for( index = 0; index < elementCount(); index ++ )
  {
    temp = node_index[ index ];
    
    // Null nodes -> no, we haven't sorted the list correctly..
    if( !temp )
    {
      free( array );
      return FALSE;
    }
    
    // Strings? You should have known better than to attempt sorting these..
    if( temp->content_type != CT_INT )
    {
      free( array );
      return FALSE;
    }
    
    array[ index ] = (int) temp->contents;
  }
  
  // Let Mr. ANSI do our sorting..
  
  qsort( array,                      // Array
        elementCount(),             // Num elements
        sizeof( int ),              // Element size
        &Qsort_Int_Compare );       // Compare function
  
  // Oh dear.. time to copy the array contents back into the vector..
  
  for( index = 0; index < elementCount(); index ++ )
    setElementAt( index, array[ index ] );
  
  free( array );
  return TRUE;
}


//--------------------------------------------------------------------------
// sortDblAscending() - sorts a vector into ascending order (numeric only)
//                      This method will return TRUE if successful.
//--------------------------------------------------------------------------
BOOL Vector::sortDblAscending( void )
{ 
  int     index;
  double *array;
  VNODE  *temp;
  
  // In order to make use of the ANSI qsort() function we need the vector
  // converted into an array. 
  
  array = (double *) malloc( sizeof( double ) * elementCount() );
  
  if( !array )
    return FALSE;
  
  for( index = 0; index < elementCount(); index ++ )
  {
    temp = node_index[ index ];
    
    // Null nodes -> no, we haven't sorted the list correctly..
    if( !temp )
    {
      free( array );
      return FALSE;
    }
    
    // Strings? You should have known better than to attempt sorting these..
    if( temp->content_type != CT_DBL )
    {
      free( array );
      return FALSE;
    }
    
    array[ index ] = temp->dbl_contents;
  }
  
  // Let Mr. ANSI do our sorting..
  
  qsort( array,                      // Array
        elementCount(),             // Num elements
        sizeof( int ),              // Element size
        &Qsort_Dbl_Compare );       // Compare function
  
  // Oh dear.. time to copy the array contents back into the vector..
  
  for( index = 0; index < elementCount(); index ++ )
    setElementDblAt( index, array[ index ] );
  
  free( array );
  return TRUE;
}

//--------------------------------------------------------------------------
// sortPtrAscending() - sorts a vector into ascending order (custom objects only)
//                      This method will return TRUE if successful.
//--------------------------------------------------------------------------
BOOL Vector::sortPtrAscending( QSORTFUNC pfnQSortFunc )
{
  int     index;
  void  **array;
  VNODE  *temp;
  Vector  v_temp;
  
  // In order to make use of the ANSI qsort() function we need the vector
  // converted into an array. 
  
  array = (void **) malloc( sizeof( void * ) * elementCount() );
  
  if( !array )
    return FALSE;
  
  // Make a duplicate of this vector first..
  v_temp.copy( this );
  
  for( index = 0; index < v_temp.elementCount(); index ++ )
  {
    temp = v_temp.node_index[ index ];
    
    // Null nodes -> no, we haven't sorted the list correctly..
    if( !temp )
    {
      free( array );
      return FALSE;
    }
    
    // Anything other than pointers?
    if( temp->content_type != CT_PTR )
    {
      free( array );
      return FALSE;
    }
    
    array[ index ] = (void *) temp->contents;
  }
  
  // Let Mr. ANSI do our sorting..
  
  qsort( array,                      // Array
        v_temp.elementCount(),      // Num elements
        sizeof( void * ),            // Element size
        pfnQSortFunc );       // Compare function
  
  // Delete everything in the current vector..
  removeAll();
  
  // Oh dear.. copy the sorted strings into this vector..
  for( index = 0; index < v_temp.elementCount(); index ++ )
    addElement( array[ index ] );
  
  free( array );
  return TRUE;
}

//--------------------------------------------------------------------------
// Qsort_Str_Compare() - string compare function for the qsort() function
//--------------------------------------------------------------------------
int Qsort_Str_Compare( const void *arg1, const void *arg2 )
{
  char *key     = (* ((char **) arg1) );
  char *element = (* ((char **) arg2) );
  
  return stricmp( key, element );
}

//--------------------------------------------------------------------------
// Qsort_Str_Compare2() - string compare function for the qsort() function
//--------------------------------------------------------------------------
int Qsort_Str_Compare2( const void *arg1, const void *arg2 )
{
  Vector::VNODE *pKey     = (* ((Vector::VNODE **) arg1) );
  Vector::VNODE *pElement = (* ((Vector::VNODE **) arg2) );
  
  char *key     = (char *) pKey->contents;
  char *element = (char *) pElement->contents;
  
  return stricmp( key, element );
}

//--------------------------------------------------------------------------
// sortStrAscending() - sorts a vector into ascending order (strings only)
//                      This method will return TRUE if successful.
//--------------------------------------------------------------------------
BOOL Vector::sortStrAscending( void )
{
  // Let Mr. ANSI do our sorting..
  qsort( node_index,                  // Array
        elementCount(),              // Num elements
        sizeof( VNODE * ),            // Element size
        &Qsort_Str_Compare2 );       // Compare function
  
  return TRUE;
}

//--------------------------------------------------------------------------
// Qsort_Int_Compare() - integer compare function for the qsort() function
//--------------------------------------------------------------------------
int Qsort_Int_Compare( const void *arg1, const void *arg2 )
{
  int key     = (*((int *) arg1));
  int element = (*((int *) arg2));
  
  if( key < element )
    return -1;
  else
  if( key > element )
    return 1;
  else
    return 0;
}


//--------------------------------------------------------------------------
// Qsort_Dbl_Compare() - double compare function for the qsort() function
//--------------------------------------------------------------------------
int Qsort_Dbl_Compare( const void *arg1, const void *arg2 )
{
  double key     = (*((double *) arg1));
  double element = (*((double *) arg2));
  
  if( key < element )
    return -1;
  else
    if( key > element )
      return 1;
    else
      return 0;
}

//--------------------------------------------------------------------------
// copyTo() - copies the contents of this vector to v
//--------------------------------------------------------------------------
void Vector::copyTo( Vector *v )
{
  VNODE *temp;
  
  v->removeAll();
  
  temp = list;
  
  for( int index = 0; index < elementCount(); index ++ )
  {
    // PDS: Skip any nodes that are deleted..
    if( temp->deletionMarked )
    {
      temp = temp->next;
      continue;
    }
    
    if( temp->content_type == CT_INT )
      v->addElement( elementIntAt( index ) );
    else
      if( temp->content_type == CT_DBL )
        v->addElementDbl( elementDblAt( index ) );
      else
        if( temp->content_type == CT_STR )
          v->addElement( elementStrAt( index ) );
        else
          v->addElement( elementPtrAt( index ) );
    
    v->setSecondaryAt( index, secondaryPtrAt( index ) );
    
    temp = temp->next;
  }
}

//--------------------------------------------------------------------------
// removeUniqueElement() - removes first occurrence of an element
//--------------------------------------------------------------------------
void Vector::removeUniqueElement( int element )
{
  int nIndex = indexOf( element );
  
  if( nIndex < 0 )
    return;
  
  removeElementAt( nIndex );
}

//--------------------------------------------------------------------------
// removeUniqueElement() - removes first occurrence of an element
//--------------------------------------------------------------------------
void Vector::removeUniqueElement( char *element )
{
  int nIndex = indexOf( element );
  
  if( nIndex < 0 )
    return;
  
  removeElementAt( nIndex );
}

//--------------------------------------------------------------------------
// addUnique()
//--------------------------------------------------------------------------
void Vector::addUnique( int element )
{
  int nIndex = indexOf( element );
  
  if( nIndex < 0 )
    addElement( element );
}


//--------------------------------------------------------------------------
// addUnique()
//--------------------------------------------------------------------------
void Vector::addUnique( char *element )
{
  int nIndex = indexOf( element );
  
  if( nIndex < 0 )
    addElement( element );
}


//--------------------------------------------------------------------------
// getParent()
//
// PDS: This is used to retrieve a backpointer to a parent.. You can use this
//      when you want to make trees out of Vectors.. ie. for when you need
//      to traverse back up the tree. ;-)
//--------------------------------------------------------------------------
void *Vector::getParent( void )
{
  return m_pParent;
}


//--------------------------------------------------------------------------
// setParent()
//--------------------------------------------------------------------------
void Vector::setParent( void *pParent )
{
  m_pParent = pParent;
}


//--------------------------------------------------------------------------
// markElementDeletedAt()
//--------------------------------------------------------------------------
BOOL Vector::markElementDeletedAt( int index )
{
  // PDS: Don't try deleting a node thats not there..
  if( index >= num_nodes )
    return FALSE;
  
  VNODE *temp = node_index[ index ];
  
  if( temp )
    temp->deletionMarked = TRUE;
  
  return TRUE;
}


//--------------------------------------------------------------------------
// purgeDeletedElements()
//--------------------------------------------------------------------------
void Vector::purgeDeletedElements( void )
{
  if( num_nodes < 1 )
    return;
  
  int    i = 0;
  VNODE *temp;
  int    nNodeCount;
  
  // PDS: Get the node count now - num_nodes will change as we delete items!
  nNodeCount = num_nodes;
  
  for( int nCount = 0; nCount < nNodeCount; nCount ++ )
  {
    temp = node_index[ i ];
    
    if( temp->deletionMarked )
    {
      // PDS: Remove the node..
      removeElementAt( i );
      
      // PDS: DO NOT advance the node index as something will have filled its place..
    }
    else
    {
      // PDS: Move to next node..
      i ++;
    }
  }
}

//--------------------------------------------------------------------------
// reverse()
//
// PDS: Sorts a vector into reverse order
//--------------------------------------------------------------------------
BOOL Vector::reverse( void )
{
  long    lIndexSize;
  VNODE **oldIndex;
  
  lIndexSize = sizeof( VNODE * ) * num_nodes;
  oldIndex   = ( VNODE ** ) malloc( lIndexSize );
  
  memcpy( oldIndex, node_index, lIndexSize );
  
  for( int i = 0; i < num_nodes; i ++ )
  {
    node_index[ i ] = oldIndex[ num_nodes - 1 - i ];
  }
  
  free( oldIndex );
  return TRUE;
}

//--------------------------------------------------------------------------
// shuffle()
//--------------------------------------------------------------------------
void Vector::shuffle( void )
{
  Vector vNewIndices;
  Vector vOldIndices;
  int    nRandIndex;

  for( int i = 0; i < num_nodes; i ++ )
    vOldIndices.addElement( (void *) node_index[ i ] );
  
  // PDS: Randomly place all the nodes until all gone..
  for( ;; )
  {
    if( ( vNewIndices.elementCount() >= num_nodes ) ||
        ( vOldIndices.elementCount() < 1 ) )
      break;
    
    nRandIndex = rand() % vOldIndices.elementCount();
    
    // PDS: Already placed, look for another..
    void *p = vOldIndices.elementPtrAt( nRandIndex );
    
    vNewIndices.addElement( p );
    
    vOldIndices.removeElementAt( nRandIndex );
  }
  
  for( int i = 0; i < num_nodes; i ++ )
    node_index[ i ] = (VNODE *) vNewIndices.elementPtrAt( i );
}

//--------------------------------------------------------------------------
// exportToFileInt()
//
// Int Optimised
//--------------------------------------------------------------------------
BOOL Vector::exportToFileInt( char * /*pszTag*/, char *pszFile, PROGRESSFUNC pfnProgress )
{
  int    nElements = elementCount();
  
  if( nElements < 1 )
    return FALSE;
  
  int    i;
  VNODE *temp = node_index[ 0 ];
  
  // PDS: Can't export pointer nodes..
  if( temp && temp->content_type != CT_INT )
    return FALSE;
  
  FILE *fOut;
  
  remove( pszFile );
  
  fOut = fopen( pszFile, "wb" );
  
  int nVal;
  
  for( i = 0; i < nElements; i ++ )
  {
    temp = node_index[ i ];
    
    if( ! temp )
    {
      fclose( fOut );
      return FALSE;
    }
  
    nVal = (int) temp->contents;
    fwrite( &nVal, 1, sizeof( int ), fOut );
  }
  
  fclose( fOut );
  
  return TRUE;
}

//--------------------------------------------------------------------------
// importFromFileInt()
//--------------------------------------------------------------------------
BOOL Vector::importFromFileInt( char * /*pszTag*/, char *pszFile, PROGRESSFUNC pfnProgress )
{
  long  lSize = FileSize( pszFile );
  int   nLastPercent = 0;
  int   nPercent     = 0;
  int   nSteps       = 4;
  int   nInts        = lSize / sizeof( int );
  
  removeAll();
  
  // PDS: PROGRESSFUNC( step, numberSteps, stepPercentage )
  if( pfnProgress )
    pfnProgress( 1, nSteps, 0 );
  
  FILE *fIn = fopen( pszFile, "rb" );
  
  if( ! fIn )
    return FALSE;

  int nTmp;
  
  for( int i = 0; i < nInts; i ++ )
  {
    fread( &nTmp, 1, sizeof( int ), fIn );

    addElement( nTmp );
    
    if( pfnProgress )
    {
      // PDS: Progress callback..
      nPercent = ( i * 100 ) / nInts;
      
      if( nPercent != nLastPercent )
      {
        pfnProgress( 4, nSteps, nPercent );
        nLastPercent = nPercent;
      }
    }
  }
 
  fclose( fIn );
  
  return TRUE;
}


//--------------------------------------------------------------------------
// exportToFile()
//--------------------------------------------------------------------------
BOOL Vector::exportToFile( char *pszTag, char *pszFile, PROGRESSFUNC pfnProgress, BOOL fAppend )
{
  int    nElements = elementCount();
  
  if( nElements < 1 )
    return FALSE;
  
  int    i;
  VNODE *temp = node_index[ 0 ];
  
  // PDS: Can't export pointer nodes..
  if( temp && temp->content_type == CT_PTR )
    return FALSE;
  
  FILE *fOut;
  
  if( FileSize( pszFile ) == 0 )
    remove( pszFile );
  
  fOut = fopen( pszFile, ( fAppend ) ? "ab" : "wb" );
  
  fprintf( fOut, "[%s]\x0d\x0a", pszTag );
  
  for( i = 0; i < nElements; i ++ )
  {
    temp = node_index[ i ];
    
    if( ! temp )
    {
      fclose( fOut );
      return FALSE;
    }
    
    switch( temp->content_type )
    {
      case CT_STR:
      {
        // PDS: This should be stored at the time of modification instead of recalculating during export!
        int   nLen = strlen( (char *) temp->contents );
        int   c;
        char *p = (char *) temp->contents;
        
        for( c = 0; c < nLen; c ++ )
        {
          // PDS: Escape various chars..
          switch( *p )
          {
            case '[':
            case '\\':
            case ']':
              fputc( '\\', fOut );
              break;
          }
          
          fputc( *p, fOut );
          p ++;
        }
        
        fprintf( fOut, "\x0d\x0a" );
        break;
      }
        
      case CT_INT:
        fprintf( fOut, "I:%d\x0d\x0a", (int) temp->contents );
        break;
        
      case CT_DBL:
        fprintf( fOut, "D:%lf\x0d\x0a", (double) temp->dbl_contents );
        break;
    }
  }
  
  fclose( fOut );
  
  return TRUE;
}

//--------------------------------------------------------------------------------------------
// ReadLine()
//--------------------------------------------------------------------------------------------
int ReadLine( char **pSrc, char *pLineBuf, int nMaxLine, char *pEof )
{
  int  i;
  char *p = (*pSrc);
  char *pOut;
  char  c;
  BOOL  fEndOfLine = FALSE;
  
  pOut = pLineBuf;
  
  for( i = 0; i < nMaxLine; i ++ )
  {
    c = (*p);
    
    // PDS: End of file reached?
    if( p >= pEof )
    {
      (*pOut) = 0;
      fEndOfLine = TRUE;
    }
    
    if( c == 0 )
    {
      fEndOfLine = TRUE;
    }
    else
      if( ( c == LF ) || ( c == CR ) )
      {
        if( ( i == 0 ) || ( i == 1 ) )
        {
          // PDS: Skip if first/second char is CR or LF..
          p ++;
          continue;
        }
        fEndOfLine = TRUE;
      }
    
    if( fEndOfLine )
    {
      (*pOut) = 0;
      (*pSrc) = p;
      int nLineSize = (long)( pOut - pLineBuf );
      return nLineSize;
    }
    
    *pOut = *p;
    
    pOut ++;
    p ++;
  }
  
  // PDS: No end of line found in buffer..
  return -1;
}

//--------------------------------------------------------------------------------------------
// ParseTextFileToLinesVector()
//--------------------------------------------------------------------------------------------
void ParseTextFileToLinesVector( char *pData, DWORD dwSize, Vector *pvLines, PROGRESSFUNC pfnProgress, int nStep, int nSteps )
{
  char *p = pData;
  //char *pComment;
  char  lineBuf[ 400 ];
  int   nLineSize;
  char *pEof;
  char *pLast = p;
  int   nLastPercent = 0;
  int   nPercent     = 0;
  
  // PDS: Find out where the file ends..
  pEof = (char*)( pData + dwSize );
  
  long lStart = (long) p;
  long lOffset;
  
  for( ;; )
  {
    lOffset = (long) p - lStart;
    
    nLineSize = ReadLine( &p, lineBuf, sizeof( lineBuf ), pEof );
    
    if( pfnProgress )
    {
      // PDS: Progress callback..
      nPercent = ( lOffset * 100 ) / dwSize;
      
      if( nPercent != nLastPercent )
      {
        pfnProgress( nStep, nSteps, nPercent );
        nLastPercent = nPercent;
      }
    }
    
    if( (long)( p ) > (long)( pData + dwSize ) )
      break;
    
    if( nLineSize < 0 )
      break;
    
    // PDS: No pointer change - get out!
    if( p == pLast )
      break;
    
    pLast = p;
    
    strtrim( lineBuf );
    
    // PDS: Ignore blank lines..
    if( strlen( lineBuf ) < 1 )
      continue;
    
    // PDS: Don't bother adding commented lines..
    //if( lineBuf[ 0 ] == COMMENT_CHAR )
    //  continue;
    
    // PDS: Now look for comment elsewhere in line..
    //pComment = strchr( lineBuf, COMMENT_CHAR );
    
    // PDS: Truncate at comment..
    //if( pComment )
    //(*pComment) = 0;
    
    pvLines->addElement( lineBuf );
  }
}

//--------------------------------------------------------------------------
// GetStringWithoutEscapes()
//
// PDS: Returns TRUE if new tag found
//--------------------------------------------------------------------------
BOOL GetStringWithoutEscapes( char *pLine, char *pTxtNoEsc )
{
  char *pSrc = pLine;
  char *pDst = pTxtNoEsc;
  
  for( ;; )
  {
    // PDS: Tag found at start of line..
    if( ( (*pSrc) == '[' ) && ( pSrc == pLine ) )
      return TRUE;
    
    if( (*pSrc) == '\\' )
    {
      // PDS: Skip escape character..
      pSrc ++;
    }
    
    // PDS: Add char..
    *pDst = *pSrc;
    
    if( *pSrc == 0 )
      break;
    
    pSrc ++;
    pDst ++;
  }
  
  return FALSE;
}

//--------------------------------------------------------------------------
// importFromFile()
//--------------------------------------------------------------------------
BOOL Vector::importFromFile( char *pszTag, char *pszFile, PROGRESSFUNC pfnProgress )
{
  long  lSize = FileSize( pszFile );
  char *pBuffer = (char *) malloc( lSize );
  int   nLastPercent = 0;
  int   nPercent     = 0;
  int   nSteps       = 4;
  
  if( ! pBuffer )
    return FALSE;
  
  // PDS: PROGRESSFUNC( step, numberSteps, stepPercentage )
  if( pfnProgress )
    pfnProgress( 1, nSteps, 0 );
  
  FILE *fIn = fopen( pszFile, "rb" );
  
  if( ! fIn )
  {
    free( pBuffer );
    return FALSE;
  }
  
  fread( pBuffer, 1, lSize, fIn ); 
  fclose( fIn );

  if( pfnProgress )
    pfnProgress( 2, nSteps, 0 );
  
  Vector vLines;
  
  ParseTextFileToLinesVector( pBuffer, lSize, &vLines, pfnProgress, 2, nSteps );
  
  free( pBuffer );
  
  char txTag[ 100 ];
  char txTxt[ 4096 ];
  
  strcpy( txTag, "[" );
  strcat( txTag, pszTag );
  strcat( txTag, "]" );
  
  // PDS: Now copy across what we want based on the tag..
  int i = vLines.indexOf( txTag );
  
  if( i < 0 )
    return FALSE;
  
  // PDS: Advance to next line (element)..
  i ++;
  
  int  nLines = vLines.elementCount();
  BOOL fNewTagFound;
  
  // PDS: Now copy all elements..
  for( ; i < nLines; i ++ )
  {
    if( pfnProgress )
    {
      // PDS: Progress callback..
      nPercent = ( i * 100 ) / nLines;
      
      if( nPercent != nLastPercent )
      {
        pfnProgress( 4, nSteps, nPercent );
        nLastPercent = nPercent;
      }
    }
    
    char *pLine = vLines.elementStrAt( i );
    
    fNewTagFound = GetStringWithoutEscapes( pLine, txTxt );
    
    // PDS: Stop if new tag found..
    if( fNewTagFound )
      break;
    
    if( ( txTxt[ 0 ] == 'I' ) && ( txTxt[ 1 ] == ':' ) )
    {
      int nValue = atoi( &txTxt[ 2 ] );
      addElement( nValue );
    }
    else
    if( ( txTxt[ 0 ] == 'D' ) && ( txTxt[ 1 ] == ':' ) )
    {
      double dblValue = atof( &txTxt[ 2 ] );
      addElementDbl( dblValue );
    }
    else
    {
      addElement( txTxt );
    }
  }
  
  return TRUE;
}

