//
//  FuseAdapterDelegate.h
//  vMount
//
//  Created by Dirk Hoffmann on 27.11.25.
//

typedef void AdapterCallback(const void *, int);

class FuseAdapterDelegate {

public:

    virtual void hello() = 0;
};
