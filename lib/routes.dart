import 'package:flutter/material.dart';
import 'pages/album_page.dart';
import 'pages/auth_page.dart';
import 'pages/gallery_page.dart';
import 'pages/home_page.dart';
import 'pages/main_tab_page.dart';
import 'pages/map_page.dart';
import 'pages/settings_page.dart';
import 'pages/sign_in_page.dart';
import 'pages/sns_page.dart';
import 'pages/tag_lens_page.dart';
import 'pages/user_create_page.dart';
import 'pages/user_signin_page.dart';

class AppRoutes {
  static const String auth = '/';
  static const String home = '/home';
  static const String mainTab = '/main_tab';
  static const String gallery = '/gallery';
  static const String album = '/album';
  static const String map = '/map';
  static const String settings = '/settings';
  static const String signIn = '/sign_in';
  static const String sns = '/sns';
  static const String tagLens = '/tag_lens';
  static const String userCreate = '/user_create';
  static const String userSignin = '/user_signin';

  static Map<String, WidgetBuilder> get routes {
    return {
      auth: (context) => const AuthPage(),
      home: (context) => const HomePage(),
      mainTab: (context) => const MainTabPage(),
      gallery: (context) => const GalleryPage(),
      album: (context) => const AlbumPage(),
      map: (context) => const MapPage(),
      settings: (context) => const SettingsPage(),
      signIn: (context) => const SignInPage(),
      sns: (context) => const SnsPage(),
      tagLens: (context) => const TagLensPage(),
      userCreate: (context) => const UserCreatePage(),
      userSignin: (context) => const UserSigninPage(),
    };
  }
}
