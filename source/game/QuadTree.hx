package game;

class Rectangle
{
    public var x:Float;
    public var y:Float;
    public var width:Float;
    public var height:Float;
    public function new(x:Float = 0., y:Float=0., width:Float=0., height:Float=0.)
    {
        this.x = x;
        this.y = y;
        this.height = height;
        this.width = width;
    }
}
class QuadTree
{
    static var MAX_OBJECTS = 10;
    static var MAX_LEVELS = 6;

    public var level:Int;
    public var objects:List<Object>;
    public var bounds:Rectangle;
    public var nodes:Array<QuadTree>;

    public function new(lvl:Int,bounds:Rectangle)
    {
        this.level = lvl;
        this.bounds = bounds;

        nodes = [];
        objects = new List<Object>();
    }

    public function clear()
    {
        objects.clear();

        for(t in 0...nodes.length)
        {
            nodes[t].clear();
            nodes[t] = null;
        }
    }

    private function split()
    {
        var subWidth = Std.int(bounds.width / 2);
        var subHeight = Std.int(bounds.height / 2);

        nodes[0] = new QuadTree(level+1,new Rectangle( bounds.x, bounds.y, subWidth, subHeight));
        nodes[1] = new QuadTree(level+1,new Rectangle( bounds.x + subWidth, bounds.y, subWidth, subHeight));
        nodes[2] = new QuadTree(level+1,new Rectangle( bounds.x, bounds.y + subHeight, subWidth, subHeight));
        nodes[3] = new QuadTree(level+1,new Rectangle( bounds.x + subWidth, bounds.y + subHeight, subWidth, subHeight));
    }

    private function getIndex(obj:Object)
    {
        var index = -1;

        var verticalMidpoint = bounds.x + bounds.width / 2;
        var horizontalMidpoint = bounds.y + bounds.height / 2;

        // Object can completely fit within the top quadrants
        var topQuadrant = (obj.y < horizontalMidpoint && obj.y + obj.height < horizontalMidpoint);
        // Object can completely fit within the bottom quadrants
        var bottomQuadrant = (obj.y > horizontalMidpoint);
 
        // Object can completely fit within the left quadrants
        if (obj.x < verticalMidpoint && obj.x + obj.width < verticalMidpoint) 
        {
            if (topQuadrant)
                index = 0;
            else if (bottomQuadrant)
                index = 2;
        }
        // Object can completely fit within the right quadrants
        else if (obj.x > verticalMidpoint) 
        {
            if (topQuadrant)
                index = 1;
            else if (bottomQuadrant)
                index = 3;
        }
 
        return index;
    }

    public function insert(obj:Object) 
    {
        if (nodes[0] != null) 
        {
            var index = getIndex(obj);
            if (index != -1)
            {
                nodes[index].insert(obj);
                return;
            }
        }

 
        objects.add(obj);
 
        if (objects.length > MAX_OBJECTS && level < MAX_LEVELS) 
        {
            if (nodes[0] == null) { 
                split(); 
            }

            if(objects.length > 0)
                for(o in objects) 
                {
                    var index = getIndex(o);
                    if (index != -1) 
                    {
                        objects.remove(o);
                        nodes[index].insert(o);
                    }
                }
        }
    }

    public function retrieve( obj:Object, list:List<Object>)
    {
        var index = getIndex(obj);
        if (index != -1 && nodes[0] != null)
            nodes[index].retrieve(obj, list);

        if(objects.length > 0)
            for(o in objects)
                list.add(o);
 
        return list;
    }
}