import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:soul_matcher/app/core/constants/admob_config.dart';

class AdMobBanner extends StatefulWidget {
  const AdMobBanner({
    super.key,
    this.adSize = AdSize.banner,
    this.margin = EdgeInsets.zero,
  });

  final AdSize adSize;
  final EdgeInsetsGeometry margin;

  @override
  State<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends State<AdMobBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  String? _errorMessage;
  int _retryCount = 0;

  static const int _maxRetryCount = 2;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    if (!AdMobConfig.isSupportedPlatform) {
      if (kDebugMode) {
        setState(() {
          _errorMessage = 'Ads support only Android/iOS.';
        });
      }
      return;
    }

    final String adUnitId = AdMobConfig.bannerAdUnitId;
    if (adUnitId.isEmpty) {
      if (kDebugMode) {
        setState(() {
          _errorMessage = 'Ad unit id is empty.';
        });
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('AdMob: loading banner ad with unitId=$adUnitId');
    }

    final BannerAd bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _isLoaded = true;
            _errorMessage = null;
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          if (!mounted) return;
          if (kDebugMode) {
            debugPrint(
              'AdMob: banner failed (code: ${error.code}) ${error.message}',
            );
          }
          setState(() {
            _isLoaded = false;
            _bannerAd = null;
            _errorMessage = 'code ${error.code}: ${error.message}';
          });
          if (_retryCount < _maxRetryCount) {
            _retryCount++;
            Future<void>.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _loadBanner();
              }
            });
          }
        },
      ),
    );

    bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BannerAd? bannerAd = _bannerAd;
    if (!_isLoaded || bannerAd == null) {
      if (kDebugMode && _errorMessage != null) {
        return Container(
          margin: widget.margin,
          width: double.infinity,
          height: widget.adSize.height.toDouble(),
          alignment: Alignment.center,
          color: Colors.black12,
          child: Text(
            'Ad not loaded: $_errorMessage',
            maxLines: 2,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }
      return SizedBox(
        height: widget.adSize.height.toDouble(),
        width: double.infinity,
      );
    }

    return Container(
      alignment: Alignment.center,
      margin: widget.margin,
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }
}
