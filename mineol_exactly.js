var gameFlagType = {
		'before_start': 'before start',
		'ing': 'gaming',
		'fail': 'failed',
		'success': 'success'
	},
	backgroundColors = {
		'unknown': 'rgb(159, 216, 248)',
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
var bindGameFlag = function () {
	var gameDiv = PARG.$drawTarget.append('<div/>').find(':last');
	gameDiv.css({
		left: '800px',
		top: '800px',
		'font-size': '-webkit-xxx-large'
	});
	return function (flag) {
		gameFlag = flag;
		gameDiv[0].innerHTML = '' + flag;
	};
};
bindGameFlag = bindGameFlag();
var getRectNearbyXY = function(x, y){
	var temp = [];
	for(var i=-1;i<2;++i){
		for(var j=-1;j<2;++j){
			temp.push([x+i,y+j]);
		}
	}
	return temp.filter(
		function (e) {
			return !((e[0]<0 || e[1]<0)||(e[0] === x && e[1] === y));
	});
};
//debug = getRectNearbyXY;
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
		$isClear = 2,
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
			that.changeBackColor(backgroundColors.unknown);
			return;
		}
	};
	var transferAmongFsms = function (nextFsm) {
		that.it.removeEventListener('mousedown', $fsm.mousedown);
		that.it.removeEventListener('mouseup', $fsm.mouseup);
		that.it.removeEventListener('click', $fsm.click);
		$fsm = nextFsm;
		that.it.addEventListener('mousedown', $fsm.mousedown);
		that.it.addEventListener('mouseup', $fsm.mouseup);
		that.it.addEventListener('click', $fsm.click);
		that.it.oncontextmenu = $fsm.contextmenu;// 不知为什么这个事件用上面的方法不行
	};

	var when_unknown = {
			mousedown: function (e) {
				if(e.which === 1){
					//left
					that.changeBackColor(backgroundColors.mousedown);
					downBuffer.push(recoverFormDown);
				}
				else if(e.which === 3){
					//right
				}
			},
			mouseup: function (e) {

			},
			click: function (e) {
				//貌似click只是指左键
				if(exactStatus === rectStatus['isMine']){
					bindGameFlag(gameFlagType.fail);
//					todo 结束
				}
				else if(exactStatus === rectStatus['clear']){
					status = rectStatus['clear'];
					that.changeBackColor(backgroundColors.clear);
					if(mineNumNearby !== 0){
						that.changeInnerContent(''+mineNumNearby);
					}
					else if(mineNumNearby === 0){
						rectNearby.forEach(function (v) {
							v.expand();
						})
					}
					transferAmongFsms($fsmChoice.clear);
				}
				console.log(mineNumNearby);
			},
			contextmenu: function (e) {
				status = rectStatus['isMine'];
				that.changeBackColor(backgroundColors.ismine);
				transferAmongFsms($fsmChoice.ismine);
				return false;
			}
		},
		when_clear = {
			mousedown: function (e) {
//				 扫描周围(视觉部分)
				rectNearby.forEach(function (v) {
					v.centerMouseDown();
				})
			},
			mouseup: function (e) {

			},
			click: function (e) {
				//---------------todo to be enhanced here------
				var $temp = rectNearby.filter(function (v) {
					return v.isMineStatusNotMatch();
				});
				if ($temp.length !== 0){
					bindGameFlag(gameFlagType.fail);
//					todo game over
				}
				//---------------------------------------------
				if(rectNearby.every(function (v) {
					return v.isClearEx();
				})){
					rectNearby.forEach(function (v) {
						v.expand();
					})
				}
			},
			contextmenu: function (e) {
				return false;
			}
		},
		when_isMine = {
			mousedown: function (e) {

			},
			mouseup: function (e) {

			},
			click: function (e) {
				
			},
			contextmenu: function (e) {
				status = rectStatus['unknown'];
				that.changeBackColor(backgroundColors.unknown);
				transferAmongFsms($fsmChoice.unknown);
				return false;
			}
		},
		$fsmChoice = {
			'init': when_unknown,
			'unknown': when_unknown,
			'clear': when_clear,
			'ismine': when_isMine
		},
		$fsm = $fsmChoice.init;

	return {
//		isMine: function () {
//			return !!(status & $isMine);
//		},
		isClear: function () {
			return (status & $isClear);
		},
		isXY: function (tx, ty) {
			return (tx === x) && (ty === y);
		},
		fillSomeThing: function (rectTable) {
			var $rectNearby = [];
			var $mineNum = 0;
			for(var i=0;i<rectTable.length;++i){
				for(var j=0;j<$rectNearbyXY.length;++j){
					if(rectTable[i].isXY($rectNearbyXY[j][0], $rectNearbyXY[j][1])){
						$rectNearby.push(rectTable[i]);
					}
				}
			}
			rectNearby = $rectNearby;
//			console.log($rectNearby);
			for(var k=0;k<rectNearby.length;++k){
				if(rectNearby[k].isMineEx()){
					$mineNum++;
				}
			}
			mineNumNearby = $mineNum;
			console.log($mineNum);
		},
		isMineEx: function(){
			return !!(exactStatus & $isMine);
		},
		isClearEx: function(){
			return (exactStatus & $isClear);
		},
		isMineStatusNotMatch: function () {
			return (status === rectStatus['isMine'])&&(exactStatus !== rectStatus['isMine']);
		},
		init: function () {
			$rectNearbyXY = getRectNearbyXY(x, y);
//			console.log(getRectNearbyXY(1,2));
			that = drawer();
			that.draw(x, y);

			that.it.addEventListener('mousedown', $fsm.mousedown);
			that.it.addEventListener('mouseup', $fsm.mouseup);
			that.it.addEventListener('click', $fsm.click);
			that.it.oncontextmenu = $fsm.contextmenu;
//			that.it.addEventListener('mousedown', function (event) {
//				if (event.which == 1) {
//					console.log('left');
//					if(status !== rectStatus['isMine']) {
//						that.changeBackColor(backgroundColors.mousedown);
//						downBuffer.push(recoverFormDown);
//						upBuffer.push(recoverFromUp);
//					}
//				}
//				if (event.which == 3){
//					console.log('right');
////					return false;
//				}
//			});
//			that.it.addEventListener('mouseup', function (event) {
//				if(event.which == 1) {
//					//left
//					if($mousedownBefore) {
//						do_probe();
//					}
//					$mousedownBefore = false;
//				}
//			}, true);
//			that.it.oncontextmenu = function (event) {
//				reverseBetweenMineAndUnknown();
//				return false;
//			};
//			that.it.addEventListener('click', function (event) {
//				if(event.which == 1) {
//					//left
////					console.log(rectNearby);
//					switch (status) {
//						case rectStatus['unknown']:
//
//					}
//				}
//				if(event.which == 3){
//				else{
//					//right
//					reverseBetweenMineAndUnknown();
//				}
//			})
		},
		centerMouseDown: function () {
			if(status === rectStatus['unknown']) {
				that.changeBackColor(backgroundColors.mousedown);
				downBuffer.push(recoverFormDown);
			}
		},
		expand: function () {
			var $temp;
			status = rectStatus['clear'];
			that.changeBackColor(backgroundColors.clear);
			if(mineNumNearby !== 0){
				that.changeInnerContent(''+mineNumNearby);
			}
			transferAmongFsms($fsmChoice.clear);
			if(mineNumNearby === 0) {
				$temp = rectNearby.filter(function (v) {
					return !(v.isClear());
				});
				$temp.forEach(function (v) {
					v.expand();
				});
			}
		},
		successConfig: function () {
//			todo test needed
			status = exactStatus;
			var $temp = status == 'isMine'?'ismine':status;
			that.changeBackColor(backgroundColors[$temp]);
			transferAmongFsms($fsmChoice[$temp]);
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
	bindGameFlag(gameFlagType['before_start']);
	rects = rectsManager();
	rects.start();
	bindGameFlag(gameFlagType['ing']);
}();