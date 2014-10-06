var gameFlagType = {
		'before_start': 1,
		'ing': 2,
		'over': 4,
		'fail': 8,
		'success': 16
	},
	backgroundColors = {
		'normal': 'rgb(159, 216, 248)',
		'mousedown': "black",
		'mouseup': 'rgb(159, 216, 248)',
		'probe': 'blue',
		'clear': 'white',
		'ismine': 'red'
	},
	gameFlag = gameFlagType['before_start'],
	default_side_lengthX = 30,
	default_side_lengthY = 30,
	small_side_lengthRatio = 0.3,
	MainStartX = 367,
	MainStartY = 0,
	ROW = 16,
	COLUMN = 30,
	MINENUM = 100,
	PARG = {
		width: 32,
		height: 32,
		imagesWidth: 256,
		images: 'mineol.png',
		$drawTarget: $('#draw-target')
	},
	rectStatus = {
		'unknown': 1,
		'clear': 2,
		'isMine': 4
	};

// ------------------------------------utils ----------------------------------------
var getRectIsMine = function (x, y) {

};
var getRectNearbyXY = function(x, y){
	var temp = [];
	for(var i=-1;i<2;++i){
		for(var j=-1;j<2;++j){
			temp.push([x+i,y+j]);
		}
	}
	return temp.filter(
		function (e) {
			return ((e[0]<0 || e[1]<0)||(e[0] === x && e[1] === y));
	});
};

var genMineMap = function () {
	var mineMap = [];
	for(var i=0;i<ROW*COLUMN;++i){
		if(i<MINENUM){
			mineMap.push(rectStatus['isMine']);
		}
		else{
			mineMap.push(rectStatus['clear']);
		}
	}
	mineMap.randomPop = function () {
		var index = Math.floor(Math.random()*ROW*COLUMN)%mineMap.length,
			temp = mineMap[index];
//		console.log(index);
		delete mineMap[index];
		mineMap = mineMap.filter(function () { return true;});
		return temp;
	};
	return mineMap.randomPop;
};
var shieldRight = function () {
	$(document).bind("contextmenu",function(e){
		return false;
	});
};
// ----------------------------------------------------------------------------------
//(function () {
//	//test
//	debug = genMineMap();
//})();


var drawer = function (sideLength) {
	var parg = PARG,
		slx = (sideLength && sideLength.x)|| default_side_lengthX,
		sly = (sideLength && sideLength.y)|| default_side_lengthY,
		startX = MainStartX,
		startY = MainStartY,
		width = slx,
		height = sly,
		image = parg.images,
		elem = parg.$drawTarget.append("<div/>").find(":last"),
		$elemStyle = elem[0].style;
	elem.css({
		position: 'absolute', left:-9999,/*********************/
		width: width,
		height: height,
//		backgroundImage: 'url(' + images + ')'
		backgroundColor: 'rgb(159, 216, 248)', // init color
		border: '2px solid rgb(211, 132, 31)'
	});
	return {
		it:elem[0],
		draw: function (x, y) {
			$elemStyle.left = startX + x * slx + 'px';
			$elemStyle.top  = startY + y * sly + 'px';
		},
		changeBackColor: function (cssStr) {
			$elemStyle.backgroundColor = cssStr;
		},
		changeInnerContent: function (arg) {
			elem[0].innerHTML = arg; //to be enhanced here
		},
		destory: function () {
			elem.remove();
		}

	};
};


var rectUnit = function (x, y, exact_status, mousedownBuffer, mouseupBuffer) {
	var exactStatus = exact_status,
		status = rectStatus['unknown'],
		$rectNearbyXY = [],
		rectNearby = [],
		mineNumNearby = 0,
		downBuffer = mousedownBuffer(),
		upBuffer   = mouseupBuffer(),
		that;

	var $isMine = 4,
		$mousedownBefore = false;
	var recoverFormDown = function () {
		that.changeBackColor(backgroundColors.mouseup);
	};
	var recoverFromUp = function () {
		$mousedownBefore = false;
	};
	var reverseBetweenMineAndUnknown = function () {
		if(status === rectStatus['unknown']){
			status = rectStatus['isMine'];
			that.changeBackColor(backgroundColors.ismine);
			return;
		}
		if(status === rectStatus['isMine']){
			status = rectStatus['unknown'];
			that.changeBackColor(backgroundColors.normal);
			return;
		}
	};
	return {
//		isMine: function () {
//			return !!(status & $isMine);
//		},
//		isClear: function () {
//			return !(status & $isMine);
//		},
		isXY: function (tx, ty) {
			return (tx === x) && (ty === y);
		},
		fillSomeThing: function (rectTable) {
			var $rectNearby = [];
			var $mineNum = 0;
			for(var i=0;i<rectTable.length;++i){
				for(var j=0;j<$rectNearbyXY;++j){
					if(rectTable[i].isXY($rectNearbyXY[j][0], $rectNearbyXY[j][1])){
						$rectNearby.push(rectTable[i]);
					}
				}
			}
			rectNearby = $rectNearby;
			for(var k=0;k<rectNearby;++k){
				if(rectNearby[k].isMineEx()){
					$mineNum++;
				}
			}
			mineNumNearby = $mineNum;
		},
		isMineEx: function(){
			return !!(exactStatus & $isMine);
		},
		isClearEx: function(){
			return !(exactStatus & $isMine);
		},
		init: function () {
			$rectNearbyXY = getRectNearbyXY(x, y);
			that = drawer();
			that.draw(x, y);

			that.it.addEventListener('mousedown', function (event) {
				if (event.which == 1) {
					console.log('left');
					that.changeBackColor(backgroundColors.mousedown);
					downBuffer.push(recoverFormDown);
					upBuffer.push(recoverFromUp);
				}
				if (event.which == 3){
					console.log('right');
//					return false;
				}
			});
			that.it.addEventListener('mouseup', function (event) {
				if(event.which == 1) {
					//left
					if($mousedownBefore) {
						do_probe();
					}
					$mousedownBefore = false;
				}
			}, true);
			that.it.oncontextmenu = function (event) {
				reverseBetweenMineAndUnknown();
				return false;
			};
			that.it.addEventListener('click', function (event) {
				if(event.which == 1) {
					//left
					switch (status) {
						case rectStatus['unknown']:

					}
				}
//				if(event.which == 3){
//				else{
//					//right
//					reverseBetweenMineAndUnknown();
//				}
			})
		},
		centerMouseDown: function (successOne) {
			if(status === rectStatus['unknown']) {
				that.changeBackColor(backgroundColors.mousedown);
				downBuffer.push();
			}
		},
		destory: function(){
			that.destroy();
		}

	};


};

var rectsManager = function () {
	var rectTable = [];
	var mousedownBuffer = [];
	var mouseupBuffer   = [];
	var downCover = function () {
		return mousedownBuffer;
	};
	var upCover   = function () {
		return mouseupBuffer;
	};
//	---------------------bind  mouseup(down) to clean something
	$(document).bind('mousedown', function () {
		//recover for the rectUnit which mousedown on it but mouseup on others.
		for(var i in mouseupBuffer){
			if(mouseupBuffer.hasOwnProperty(i))
				mouseupBuffer[i]();
		}
		mouseupBuffer.length = 0;
	});
	$(document).bind('mouseup', function () {
		//recover for the rectUnit that mousedown on it changing its backcolor but not mouseup on it
		for(var i in mousedownBuffer){
			if(mousedownBuffer.hasOwnProperty(i))
				mousedownBuffer[i]();
		}
		mousedownBuffer.length = 0;
	});
//	----------------------------------------------------------------
	var do_for_start = function () {
		//----------------------generate mine map randomly
		var genMineMapFunc = genMineMap();
		for (var i = 0; i < COLUMN; ++i) {
			for (var j = 0; j < ROW; ++j) {
				var $status = genMineMapFunc(),
					aRectUnit = rectUnit(i, j, $status, downCover, upCover);
				rectTable.push(aRectUnit);
			}
		}
		// ------------------------------------------------------------
		rectTable.forEach(function (v) {
			v.init();
		});
		//--------------fill  rectNearby and  mineNumNearby in rectUnit
		rectTable.forEach(function (v) {
			v.fillSomeThing(rectTable);
		});
		//--------------------------------------------------------------
	};
	rectTable.destory = function () {
		for(var i in rectTable){
			if(rectTable.hasOwnProperty(i)){
				console.log(i);
				rectTable[i].destory();
			}
		}
		rectTable.length = 0;
	};
	return {
		restart: function(){
			rectTable.destory();
			do_for_start();
		},
		start: function(){
			do_for_start();
		}
	};
};

var game = function () {
	gameFlag = gameFlagType['before_start'];
	rects = rectsManager();
	rects.start();
	gameFlag = gameFlagType['ing']
}();