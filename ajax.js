$(document).ready(function () {
//	var mineNumber = MINENUMBER;
//	var mineHasFound = MINEHASFOUND;
//	var rectTable = RECTTABLE;

	var refreshInterval = 0.5;
		token=0;

	var $temp = new Date();
	token = $temp.getTime(); // use for config which one it is

	window.onbeforeunload = function () {
		$.ajax({
			type: 'POST',
			url: '/ajax/',
			data: {id: token, willLeave: true},
			success: function (response) {
				;
			},
			async: false,
			dataType: 'text'
		});
		return "asdads";
	};

	(function ajaxFunc() {
		$.ajax({
			type: 'POST',
			url: '/ajax/',
			data: {mineHasFound: MINEHASFOUND, id: token},
			success: function (response) {
				console.log(response);
				var res_list = response.split('id:').slice(1),
					$id,
					$mineHasFound,
					$rectTable,
					$t,
					$infoList;
				console.log(res_list);
				$infoList = res_list.map(function (v) {
					$t = v.split('mineHasFound:');
					$id = $t[0];
					delete $t[0];
					$t = $t.filter(function(){return true;})[0];
					$t = $t.split('rectTable:');
					$mineHasFound = $t[0];
					$rectTable = $t[1];
					return {
						id: parseInt($id),
						mineHasFound: parseInt($mineHasFound),
						rectTable: $rectTable
					}
				});
				console.log($infoList);
				for(var i in $infoList[0]){
					if($infoList[0].hasOwnProperty(i)) {
						P1[i] = $infoList[0][i];
					}
				}
				for(var j in $infoList[1]){
					if($infoList[1].hasOwnProperty(j)){
						P2[j] = $infoList[1][j];
					}
				}
				$('#p1').find('.percent')[0].innerHTML = ''+P1.mineHasFound;
				$('#p2').find('.percent')[0].innerHTML = ''+P2.mineHasFound;
				console.log(P1);
				console.log(P2);
			},
			dataType: 'text'
		});
		setTimeout(ajaxFunc, 1000);
	})();
});