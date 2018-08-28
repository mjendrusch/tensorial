type
  SpatialContainerKind* = enum
    qtLeaf, qtBranch, qtRoot
  SpatialContainerObj*[N; T] = object
    kind: SpatialContainerKind
    quadrant: int
    parent: SpatialContainerPtr
    children: array[2 ^ N, SpatialContainer]
    position: SpatialPosition[N]
    payload: T
  SpatialContainerPtr*[N, T] = ptr SpatialContainerObj[N, T]
  SpatialContainer*[N, T] = ref SpatialContainerObj[N, T]
  SpatialPosition*[N] = array[N, float32]

proc newSpatialContainer*[T](
  dims: static[int]; typ: type T;
  position: array[dims, float32]
): SpatialContainer[dims, T] =
  new result
  result.kind = qtRoot

proc getQuadrant*[N, T](container: SpatialContainer[N, T]; index: SpatialPosition[N]): int =
  discard
proc quadrantPosition*[N, T](container: SpatialContainer[N, T]; quadrant: int): SpatialPosition[N] =
  discard

proc retrieve*[N, T](container: SpatialContainer[N, T];
                     index: SpatialPosition[N]; neighbours: int): seq[T] =
  discard

proc add*[N, T](container: SpatialContainer[N, T]; val: T;
                index: SpatialPosition[N]) =
  case container.kind
  of qtBranch, qtRoot:
    let
      quadrant = container.getQuadrant(index)
    if container.children[quadrant].isNil:
      var
        subcontainer = newSpatialContainer(N, T, index)
      subcontainer.kind = qtLeaf
      subcontainer.payload = val
      subcontainer.parent = container
    else:
      container.children[quadrant].add(val, index)
  of qtLeaf:
    var
      parent = container.parent[]
      supercontainer = newSpatialContainer(N, T,
        parent.quadrantPosition(container.quadrant)
      )
      newQuadrant = supercontainer.getQuadrant(container.position)
    supercontainer.parent = parent.addr
    supercontainer.children[newQuadrant] = container
    container.parent = supercontainer
    parent.children[container.quadrant] = supercontainer
    supercontainer.add(val, index)

